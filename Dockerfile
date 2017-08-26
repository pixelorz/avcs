FROM ubuntu:16.04

RUN apt-get update
RUN apt-get install -y nodejs git
RUN git clone https://github.com/ajaxorg/cloud9.git
RUN cd /cloud9 && npm install

VOLUME ["/workspace"]

EXPOSE 3131
CMD ["/cloud9/bin/cloud9.sh", "-l", "0.0.0.0", "-w", "/workspace"]

CMD node /cloud9/server.js -p 80 -l 0.0.0.0 -w /workspace -a :
