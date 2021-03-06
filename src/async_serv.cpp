#include "async_serv.h"
#include "net/opcodes.h"
#include <iostream>
#include <sstream>
#include <vector>
// import bnet;
#include"protocolcxx/bnet.h"
#include"lua/luacxx.h"
#define doExit(...)                                                            \
  {                                                                            \
    eprintf(__VA_ARGS__);                                                      \
    exit(EXIT_FAILURE);                                                        \
  }

#define SBUF 1024


static opcode::opcode opcodes[] = {
    {{0x01, opcode::ignorebyte, opcode::ignorebyte, 0x01}, opcode::events::event0},
    {{'a', 'b', 'c', 'd'}, opcode::events::event1},
};
namespace serv {
struct user {// for udp; todo: change.
  std::string ip;
  uint16_t port;
  struct sockaddr_in in;
  time_t lastPing;
  bool operator==(struct sockaddr_in &s) {
    return s.sin_family == in.sin_family && s.sin_port == in.sin_port &&
           s.sin_addr.s_addr == in.sin_addr.s_addr;
  }
  user(struct sockaddr_in &s) {
    ip = inet_ntoa(s.sin_addr);
    port = htons(s.sin_port);
    in.sin_family = s.sin_family;
    in.sin_port = s.sin_port;
    in.sin_addr.s_addr = s.sin_addr.s_addr;
    updatePing();
  }
  void updatePing(void){ lastPing = time(NULL); }
};
} // namespace serv

static std::vector<serv::user> users;

constexpr auto serv_status_lua_var = "server_inited";
static bool serv_inited;
void serv_thread(struct serv_arguments * arguments) {

  const char * host = arguments-> listen_host;
  const uint16_t& port = arguments->listen_port;
  lua_State * L = arguments->luastate;

  int ret;

  struct epoll_event ev, events[MAX_LISTEN];
  int epollfd, nfds;

  int main_descriptor = socket(AF_INET, SOCK_STREAM, 0);
  int main_descriptor_udp = socket(AF_INET, SOCK_DGRAM, 0);
  if (main_descriptor == -1)
    doExit("Can't init socket\n");
  if (main_descriptor_udp == -1) {
    // maybe disable udp support
    doExit("Can't init udp support socket\n");
  }

  struct sockaddr_in my_addr;
  my_addr.sin_family = AF_INET;
  my_addr.sin_port = htons(port);
  my_addr.sin_addr.s_addr = inet_addr(host);

  ret = bind(main_descriptor, (struct sockaddr *)&my_addr,
             sizeof(struct sockaddr_in));
  if (ret == -1) {
    doExit("Can't init bind on (TCP) %s:%d\n", host, port);
  }

  ret = bind(main_descriptor_udp, (struct sockaddr *)&my_addr,
             sizeof(struct sockaddr_in));
  if (ret == -1) {
    doExit("Can't init bind on (UDP) %s:%d\n", host, port);
  }

  if (listen(main_descriptor, MAX_LISTEN) == -1)
    doExit("Cant start listening (TCP) \n");

  struct timeval tv;
  tv.tv_sec = 0;
  tv.tv_usec = 250;

  setsockopt(main_descriptor, SOL_SOCKET, SO_RCVTIMEO, (const char *)&tv,
             sizeof tv);
  setsockopt(main_descriptor_udp, SOL_SOCKET, SO_RCVTIMEO, (const char *)&tv,
             sizeof tv);

  printf("(serv) %s:%d listening (TCP+UDP)\n", host, port);
  lua::pushval(L, true);
  lua_setglobal(L, serv_status_lua_var);
  lua_pop(L, 1);
  serv_inited = true;

  /*
          epollfd
  */
  epollfd = epoll_create1(0);
  if (epollfd == -1) {
    perror("epoll_create1");
    exit(EXIT_FAILURE);
  }
  ev.events = EPOLLIN;
  ev.data.fd = main_descriptor;
  if (epoll_ctl(epollfd, EPOLL_CTL_ADD, main_descriptor, &ev) == -1) {
    perror("epoll_ctl: main_descriptor");
    exit(EXIT_FAILURE);
  }
  ev.events = EPOLLIN | EPOLLET;
  ev.data.fd = main_descriptor_udp;
  if (epoll_ctl(epollfd, EPOLL_CTL_ADD, main_descriptor_udp, &ev) == -1) {
    perror("epoll_ctl: main_descriptor_udp");
    exit(EXIT_FAILURE);
  }

  struct sockaddr_in client_addr;
  socklen_t sizeOfSockAddrType = sizeof(struct sockaddr_in);

  for (;;) { // for start
    puts("Cycle");
    nfds = epoll_wait(epollfd, events, MAX_LISTEN, -1);
    if (nfds == -1) {
      puts("Epoll_Wait");
      perror("epoll_wait");
      exit(EXIT_FAILURE);
    }
    puts("Now data");
    for (int n = 0; n < nfds; ++n) {

      if (events[n].data.fd == main_descriptor_udp) {
        char buf_udp[SBUF];
        size_t nbytes;
        // puts("RecvFrom");
        std::cout << "RECVFROM UDP" << std::endl;
        nbytes =
            recvfrom(events[n].data.fd, buf_udp, sizeof(buf_udp), O_NONBLOCK,
                     (sockaddr *)&client_addr, &sizeOfSockAddrType);
        if (nbytes < 0)
          continue; // timeout
        buf_udp[nbytes] = 0;
        const char *ip = inet_ntoa(client_addr.sin_addr);
        const uint16_t port = htons(client_addr.sin_port);
        printf("(UDP) %s:%d -> %s\n", ip, port, buf_udp);
        //	std::sstream tmp;
        char tmp[256];
        sprintf(tmp, "[%s:%d]: %s\n%c", ip, port, buf_udp, '\0');
        sendto(events[n].data.fd, tmp, strlen(tmp), 0,
               reinterpret_cast<struct sockaddr *>(&client_addr),
               sizeOfSockAddrType);

        bool user_exists = false;
        std::stringstream list;
        time_t timenow = time(NULL);

	auto delByPing = [&timenow](){
			auto deleted = false;
			do{
			deleted = false;
			for( auto it = users.begin(); it != users.end(); it++ ){
			   serv::user & u = *it;
			   if(timenow - u.lastPing > 120) {
				puts("Erase user(timeout): ");
				std::cout << u.ip << std::endl;
				users.erase(it);
				deleted = true;
				break;
			   }
			}
			}while(deleted);
	};

	delByPing();

        for (auto u : users) {
          if (u == client_addr) {
            puts("User exists already");
            user_exists = true;
            //    break;
	    u.updatePing();
          }
          list << u.ip << ":" << u.port << ";";
         
        }

        if (!user_exists) {
          // TODO: 	ping-pong time(NULL) ...500ms -> users.erase(usr);
	  if(users.size() > 10) users = std::vector< serv::user >{};
          serv::user usr{client_addr};
          users.push_back(usr);
        }
        std::cout << "sendto" << std::endl;
        sendto(events[n].data.fd, list.str().c_str(), list.str().size(),
               O_NONBLOCK, reinterpret_cast<struct sockaddr *>(&client_addr),
               sizeOfSockAddrType);

        // TODO: UDP handler function
        std::cout << "Continue" << std::endl;
        continue;
      } // udp

      if (events[n].data.fd == main_descriptor) { // if is main descriptor
        puts("Accept handler");
        int conn_sock = accept(main_descriptor, (struct sockaddr *)&client_addr,
                               &sizeOfSockAddrType);
        if (conn_sock == -1) {
          perror("accept");
          puts("accept");
          exit(EXIT_FAILURE);
        }
        int flags = fcntl(conn_sock, F_GETFL, 0);
        fcntl(conn_sock, F_SETFL, flags | O_NONBLOCK);

        ev.events = EPOLLIN | EPOLLET;
        ev.data.fd = conn_sock;
        if (epoll_ctl(epollfd, EPOLL_CTL_ADD, conn_sock, &ev) == -1) {
          puts("epoll_ctl");
          perror("epoll_ctl: conn_sock");
          exit(EXIT_FAILURE);
        }
	/*
		UDP will be to using for peer talks only. (?)
	*/

      }      /*if acceptor TCP*/
      else { /*if client*/
             // TODO: TCP handler function
        puts("client handler TCP");
        char buf[SBUF];
        size_t nbytes;
        const char *ip = inet_ntoa(client_addr.sin_addr);
        const uint16_t port = htons(client_addr.sin_port);
        bzero(buf, sizeof(buf));
        if ((nbytes = recv(events[n].data.fd, buf, sizeof(buf), O_NONBLOCK)) <=
            0) {
          if (errno != EWOULDBLOCK && nbytes != 0) {
            perror("read/fd2");
          }
          epoll_ctl(epollfd, EPOLL_CTL_DEL, events[n].data.fd, &ev);
          close(events[n].data.fd);
          continue;
        }
        lua_getglobal(L, serv_status_lua_var);
        serv_inited = lua_toboolean(L, -1);
        lua_pop(L, 1);

        if (!serv_inited) {
          puts("Stop server?");
          return;
        }

        /*
                           *
          opcode::opcode op1{{0x02, opcode::ignorebyte, opcode::ignorebyte,
          0x01}, NULL}; opcode::opcode op2{{0x01, opcode::ignorebyte,
          opcode::ignorebyte, 0x01}, NULL}; std::cout << (op == op2) <<
          std::endl;
          */
        bool found = false;
        opcode::opcode_data data = {buf[0], buf[1], buf[2], buf[3]};
        for (auto op : opcodes) {
          if (op == data) {
            puts("Opcode found");
            op.getEvent().run(L, events[n].data.fd, ip, port, buf);
            found = true;
            break;
          }
        } // for
        if (!found) {
          puts("Opcode not founded");
	  opcode::events::notFound(L, events[n].data.fd, ip, port, buf, data);
          // close(events[n].data.fd);
        }

        // do_use_fd(events[n].data.fd);
      } // else client
    }   // for(int n = 0; n < nfds; ++n
  }     // for(;;)
}
