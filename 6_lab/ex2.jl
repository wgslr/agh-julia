resultsChnl = Channel(500)

function makeProducer(path, ext = "")

  println("Producer starting")

  if ext == ""
    regex = Regex(".*")
  else
    regex = Regex("\\.$ext\$")
  end
  (c::Channel) -> begin
    for (root, _dirs, files) in Base.Filesystem.walkdir(path)
      matching = filter(f -> ismatch(regex, f), files)
      foreach(file -> put!(c, joinpath(root, file)), matching)
    end
    println("Producer closing hannel")
    close(c)
  end
end

function makeConsumer(inputChnl :: Channel, id)
  return () -> begin
    println("consumer $id starting")
    for file in inputChnl
      cnt = Base.DataFmt.countlines(file)
      println("Job #$id says '$file' has $cnt lines")
      put!(resultsChnl, cnt)
      yield()
    end
  end
end

consumers = 5

if length(ARGS) >= 2
  ext = ARGS[2]
elseif length(ARGS) == 0
  println("Not enough arguments! Provide path to traverse")
  exit(1)
else
  ext = ""
end

filesChnl = Channel(64)

tasks = [Task(makeConsumer(filesChnl, id)) for id=1:consumers]
foreach(schedule, tasks)

producer = makeProducer(ARGS[1], ext)
t = Task(() -> producer(filesChnl))
schedule(t)

while any(t -> !istaskdone(t), append!(tasks, [t]))
  sleep(0.1)
end

close(resultsChnl)

println("Total lines: ", sum(resultsChnl))