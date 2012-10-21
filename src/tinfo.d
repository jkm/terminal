// Copyright Jens K. Mueller
// Friedrich-Schiller-University Jena
//

module tinfo;

extern(C):
int setupterm(const(char)* term, int fildes, int *errret);
const(char)* tigetstr(const(char)* capname);
int tgetnum(const(char) *capname);
char* tparm(const(char)* str, ...);
int tputs(const(char)* str, int affcnt, int function(int) fp);
