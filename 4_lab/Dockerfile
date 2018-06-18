FROM julia

RUN apt-get update && apt-get install -y build-essential 

RUN julia -e 'Pkg.add("DifferentialEquations")'

CMD bash
