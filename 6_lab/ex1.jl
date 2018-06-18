function maketasks(tasks, iters)
  conds = [Condition() for _ in 1:tasks]
  sem = 1
  funcs = map(i -> begin
    () -> begin
      for _ in 1:iters
        while(sem != i)
          yield()
        end

        println(i)
        sem = i < tasks ? i + 1 : 1
        yield()
      end
    end
  end, 1:tasks)
  [Task(f) for f in funcs]
end

tasks = maketasks(4, 4)
foreach(t -> schedule(t), shuffle(tasks))

while any(t -> !istaskdone(t), tasks)
  sleep(0.1)
end
