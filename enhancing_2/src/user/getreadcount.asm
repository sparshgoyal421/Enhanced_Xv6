
user/_getreadcount:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:

// Reference: https://cs631.cs.usfca.edu/guides/adding-a-syscall-to-xv6

int
main(int argc, char *argv[])
{
   0:	1141                	addi	sp,sp,-16
   2:	e406                	sd	ra,8(sp)
   4:	e022                	sd	s0,0(sp)
   6:	0800                	addi	s0,sp,16
    printf("Current read count is %d\n", getreadcount());
   8:	00000097          	auipc	ra,0x0
   c:	352080e7          	jalr	850(ra) # 35a <getreadcount>
  10:	85aa                	mv	a1,a0
  12:	00000517          	auipc	a0,0x0
  16:	7de50513          	addi	a0,a0,2014 # 7f0 <malloc+0xf4>
  1a:	00000097          	auipc	ra,0x0
  1e:	62a080e7          	jalr	1578(ra) # 644 <printf>
    exit(0);
  22:	4501                	li	a0,0
  24:	00000097          	auipc	ra,0x0
  28:	28e080e7          	jalr	654(ra) # 2b2 <exit>

000000000000002c <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  2c:	1141                	addi	sp,sp,-16
  2e:	e406                	sd	ra,8(sp)
  30:	e022                	sd	s0,0(sp)
  32:	0800                	addi	s0,sp,16
  extern int main();
  main();
  34:	00000097          	auipc	ra,0x0
  38:	fcc080e7          	jalr	-52(ra) # 0 <main>
  exit(0);
  3c:	4501                	li	a0,0
  3e:	00000097          	auipc	ra,0x0
  42:	274080e7          	jalr	628(ra) # 2b2 <exit>

0000000000000046 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  46:	1141                	addi	sp,sp,-16
  48:	e422                	sd	s0,8(sp)
  4a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  4c:	87aa                	mv	a5,a0
  4e:	0585                	addi	a1,a1,1
  50:	0785                	addi	a5,a5,1
  52:	fff5c703          	lbu	a4,-1(a1)
  56:	fee78fa3          	sb	a4,-1(a5)
  5a:	fb75                	bnez	a4,4e <strcpy+0x8>
    ;
  return os;
}
  5c:	6422                	ld	s0,8(sp)
  5e:	0141                	addi	sp,sp,16
  60:	8082                	ret

0000000000000062 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  62:	1141                	addi	sp,sp,-16
  64:	e422                	sd	s0,8(sp)
  66:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  68:	00054783          	lbu	a5,0(a0)
  6c:	cb91                	beqz	a5,80 <strcmp+0x1e>
  6e:	0005c703          	lbu	a4,0(a1)
  72:	00f71763          	bne	a4,a5,80 <strcmp+0x1e>
    p++, q++;
  76:	0505                	addi	a0,a0,1
  78:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  7a:	00054783          	lbu	a5,0(a0)
  7e:	fbe5                	bnez	a5,6e <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  80:	0005c503          	lbu	a0,0(a1)
}
  84:	40a7853b          	subw	a0,a5,a0
  88:	6422                	ld	s0,8(sp)
  8a:	0141                	addi	sp,sp,16
  8c:	8082                	ret

000000000000008e <strlen>:

uint
strlen(const char *s)
{
  8e:	1141                	addi	sp,sp,-16
  90:	e422                	sd	s0,8(sp)
  92:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  94:	00054783          	lbu	a5,0(a0)
  98:	cf91                	beqz	a5,b4 <strlen+0x26>
  9a:	0505                	addi	a0,a0,1
  9c:	87aa                	mv	a5,a0
  9e:	4685                	li	a3,1
  a0:	9e89                	subw	a3,a3,a0
  a2:	00f6853b          	addw	a0,a3,a5
  a6:	0785                	addi	a5,a5,1
  a8:	fff7c703          	lbu	a4,-1(a5)
  ac:	fb7d                	bnez	a4,a2 <strlen+0x14>
    ;
  return n;
}
  ae:	6422                	ld	s0,8(sp)
  b0:	0141                	addi	sp,sp,16
  b2:	8082                	ret
  for(n = 0; s[n]; n++)
  b4:	4501                	li	a0,0
  b6:	bfe5                	j	ae <strlen+0x20>

00000000000000b8 <memset>:

void*
memset(void *dst, int c, uint n)
{
  b8:	1141                	addi	sp,sp,-16
  ba:	e422                	sd	s0,8(sp)
  bc:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  be:	ca19                	beqz	a2,d4 <memset+0x1c>
  c0:	87aa                	mv	a5,a0
  c2:	1602                	slli	a2,a2,0x20
  c4:	9201                	srli	a2,a2,0x20
  c6:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
  ca:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  ce:	0785                	addi	a5,a5,1
  d0:	fee79de3          	bne	a5,a4,ca <memset+0x12>
  }
  return dst;
}
  d4:	6422                	ld	s0,8(sp)
  d6:	0141                	addi	sp,sp,16
  d8:	8082                	ret

00000000000000da <strchr>:

char*
strchr(const char *s, char c)
{
  da:	1141                	addi	sp,sp,-16
  dc:	e422                	sd	s0,8(sp)
  de:	0800                	addi	s0,sp,16
  for(; *s; s++)
  e0:	00054783          	lbu	a5,0(a0)
  e4:	cb99                	beqz	a5,fa <strchr+0x20>
    if(*s == c)
  e6:	00f58763          	beq	a1,a5,f4 <strchr+0x1a>
  for(; *s; s++)
  ea:	0505                	addi	a0,a0,1
  ec:	00054783          	lbu	a5,0(a0)
  f0:	fbfd                	bnez	a5,e6 <strchr+0xc>
      return (char*)s;
  return 0;
  f2:	4501                	li	a0,0
}
  f4:	6422                	ld	s0,8(sp)
  f6:	0141                	addi	sp,sp,16
  f8:	8082                	ret
  return 0;
  fa:	4501                	li	a0,0
  fc:	bfe5                	j	f4 <strchr+0x1a>

00000000000000fe <gets>:

char*
gets(char *buf, int max)
{
  fe:	711d                	addi	sp,sp,-96
 100:	ec86                	sd	ra,88(sp)
 102:	e8a2                	sd	s0,80(sp)
 104:	e4a6                	sd	s1,72(sp)
 106:	e0ca                	sd	s2,64(sp)
 108:	fc4e                	sd	s3,56(sp)
 10a:	f852                	sd	s4,48(sp)
 10c:	f456                	sd	s5,40(sp)
 10e:	f05a                	sd	s6,32(sp)
 110:	ec5e                	sd	s7,24(sp)
 112:	1080                	addi	s0,sp,96
 114:	8baa                	mv	s7,a0
 116:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 118:	892a                	mv	s2,a0
 11a:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 11c:	4aa9                	li	s5,10
 11e:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 120:	89a6                	mv	s3,s1
 122:	2485                	addiw	s1,s1,1
 124:	0344d863          	bge	s1,s4,154 <gets+0x56>
    cc = read(0, &c, 1);
 128:	4605                	li	a2,1
 12a:	faf40593          	addi	a1,s0,-81
 12e:	4501                	li	a0,0
 130:	00000097          	auipc	ra,0x0
 134:	19a080e7          	jalr	410(ra) # 2ca <read>
    if(cc < 1)
 138:	00a05e63          	blez	a0,154 <gets+0x56>
    buf[i++] = c;
 13c:	faf44783          	lbu	a5,-81(s0)
 140:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 144:	01578763          	beq	a5,s5,152 <gets+0x54>
 148:	0905                	addi	s2,s2,1
 14a:	fd679be3          	bne	a5,s6,120 <gets+0x22>
  for(i=0; i+1 < max; ){
 14e:	89a6                	mv	s3,s1
 150:	a011                	j	154 <gets+0x56>
 152:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 154:	99de                	add	s3,s3,s7
 156:	00098023          	sb	zero,0(s3)
  return buf;
}
 15a:	855e                	mv	a0,s7
 15c:	60e6                	ld	ra,88(sp)
 15e:	6446                	ld	s0,80(sp)
 160:	64a6                	ld	s1,72(sp)
 162:	6906                	ld	s2,64(sp)
 164:	79e2                	ld	s3,56(sp)
 166:	7a42                	ld	s4,48(sp)
 168:	7aa2                	ld	s5,40(sp)
 16a:	7b02                	ld	s6,32(sp)
 16c:	6be2                	ld	s7,24(sp)
 16e:	6125                	addi	sp,sp,96
 170:	8082                	ret

0000000000000172 <stat>:

int
stat(const char *n, struct stat *st)
{
 172:	1101                	addi	sp,sp,-32
 174:	ec06                	sd	ra,24(sp)
 176:	e822                	sd	s0,16(sp)
 178:	e426                	sd	s1,8(sp)
 17a:	e04a                	sd	s2,0(sp)
 17c:	1000                	addi	s0,sp,32
 17e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 180:	4581                	li	a1,0
 182:	00000097          	auipc	ra,0x0
 186:	170080e7          	jalr	368(ra) # 2f2 <open>
  if(fd < 0)
 18a:	02054563          	bltz	a0,1b4 <stat+0x42>
 18e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 190:	85ca                	mv	a1,s2
 192:	00000097          	auipc	ra,0x0
 196:	178080e7          	jalr	376(ra) # 30a <fstat>
 19a:	892a                	mv	s2,a0
  close(fd);
 19c:	8526                	mv	a0,s1
 19e:	00000097          	auipc	ra,0x0
 1a2:	13c080e7          	jalr	316(ra) # 2da <close>
  return r;
}
 1a6:	854a                	mv	a0,s2
 1a8:	60e2                	ld	ra,24(sp)
 1aa:	6442                	ld	s0,16(sp)
 1ac:	64a2                	ld	s1,8(sp)
 1ae:	6902                	ld	s2,0(sp)
 1b0:	6105                	addi	sp,sp,32
 1b2:	8082                	ret
    return -1;
 1b4:	597d                	li	s2,-1
 1b6:	bfc5                	j	1a6 <stat+0x34>

00000000000001b8 <atoi>:

int
atoi(const char *s)
{
 1b8:	1141                	addi	sp,sp,-16
 1ba:	e422                	sd	s0,8(sp)
 1bc:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1be:	00054683          	lbu	a3,0(a0)
 1c2:	fd06879b          	addiw	a5,a3,-48
 1c6:	0ff7f793          	zext.b	a5,a5
 1ca:	4625                	li	a2,9
 1cc:	02f66863          	bltu	a2,a5,1fc <atoi+0x44>
 1d0:	872a                	mv	a4,a0
  n = 0;
 1d2:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 1d4:	0705                	addi	a4,a4,1
 1d6:	0025179b          	slliw	a5,a0,0x2
 1da:	9fa9                	addw	a5,a5,a0
 1dc:	0017979b          	slliw	a5,a5,0x1
 1e0:	9fb5                	addw	a5,a5,a3
 1e2:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1e6:	00074683          	lbu	a3,0(a4)
 1ea:	fd06879b          	addiw	a5,a3,-48
 1ee:	0ff7f793          	zext.b	a5,a5
 1f2:	fef671e3          	bgeu	a2,a5,1d4 <atoi+0x1c>
  return n;
}
 1f6:	6422                	ld	s0,8(sp)
 1f8:	0141                	addi	sp,sp,16
 1fa:	8082                	ret
  n = 0;
 1fc:	4501                	li	a0,0
 1fe:	bfe5                	j	1f6 <atoi+0x3e>

0000000000000200 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 200:	1141                	addi	sp,sp,-16
 202:	e422                	sd	s0,8(sp)
 204:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 206:	02b57463          	bgeu	a0,a1,22e <memmove+0x2e>
    while(n-- > 0)
 20a:	00c05f63          	blez	a2,228 <memmove+0x28>
 20e:	1602                	slli	a2,a2,0x20
 210:	9201                	srli	a2,a2,0x20
 212:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 216:	872a                	mv	a4,a0
      *dst++ = *src++;
 218:	0585                	addi	a1,a1,1
 21a:	0705                	addi	a4,a4,1
 21c:	fff5c683          	lbu	a3,-1(a1)
 220:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 224:	fee79ae3          	bne	a5,a4,218 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 228:	6422                	ld	s0,8(sp)
 22a:	0141                	addi	sp,sp,16
 22c:	8082                	ret
    dst += n;
 22e:	00c50733          	add	a4,a0,a2
    src += n;
 232:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 234:	fec05ae3          	blez	a2,228 <memmove+0x28>
 238:	fff6079b          	addiw	a5,a2,-1
 23c:	1782                	slli	a5,a5,0x20
 23e:	9381                	srli	a5,a5,0x20
 240:	fff7c793          	not	a5,a5
 244:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 246:	15fd                	addi	a1,a1,-1
 248:	177d                	addi	a4,a4,-1
 24a:	0005c683          	lbu	a3,0(a1)
 24e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 252:	fee79ae3          	bne	a5,a4,246 <memmove+0x46>
 256:	bfc9                	j	228 <memmove+0x28>

0000000000000258 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 258:	1141                	addi	sp,sp,-16
 25a:	e422                	sd	s0,8(sp)
 25c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 25e:	ca05                	beqz	a2,28e <memcmp+0x36>
 260:	fff6069b          	addiw	a3,a2,-1
 264:	1682                	slli	a3,a3,0x20
 266:	9281                	srli	a3,a3,0x20
 268:	0685                	addi	a3,a3,1
 26a:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 26c:	00054783          	lbu	a5,0(a0)
 270:	0005c703          	lbu	a4,0(a1)
 274:	00e79863          	bne	a5,a4,284 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 278:	0505                	addi	a0,a0,1
    p2++;
 27a:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 27c:	fed518e3          	bne	a0,a3,26c <memcmp+0x14>
  }
  return 0;
 280:	4501                	li	a0,0
 282:	a019                	j	288 <memcmp+0x30>
      return *p1 - *p2;
 284:	40e7853b          	subw	a0,a5,a4
}
 288:	6422                	ld	s0,8(sp)
 28a:	0141                	addi	sp,sp,16
 28c:	8082                	ret
  return 0;
 28e:	4501                	li	a0,0
 290:	bfe5                	j	288 <memcmp+0x30>

0000000000000292 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 292:	1141                	addi	sp,sp,-16
 294:	e406                	sd	ra,8(sp)
 296:	e022                	sd	s0,0(sp)
 298:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 29a:	00000097          	auipc	ra,0x0
 29e:	f66080e7          	jalr	-154(ra) # 200 <memmove>
}
 2a2:	60a2                	ld	ra,8(sp)
 2a4:	6402                	ld	s0,0(sp)
 2a6:	0141                	addi	sp,sp,16
 2a8:	8082                	ret

00000000000002aa <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2aa:	4885                	li	a7,1
 ecall
 2ac:	00000073          	ecall
 ret
 2b0:	8082                	ret

00000000000002b2 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2b2:	4889                	li	a7,2
 ecall
 2b4:	00000073          	ecall
 ret
 2b8:	8082                	ret

00000000000002ba <wait>:
.global wait
wait:
 li a7, SYS_wait
 2ba:	488d                	li	a7,3
 ecall
 2bc:	00000073          	ecall
 ret
 2c0:	8082                	ret

00000000000002c2 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2c2:	4891                	li	a7,4
 ecall
 2c4:	00000073          	ecall
 ret
 2c8:	8082                	ret

00000000000002ca <read>:
.global read
read:
 li a7, SYS_read
 2ca:	4895                	li	a7,5
 ecall
 2cc:	00000073          	ecall
 ret
 2d0:	8082                	ret

00000000000002d2 <write>:
.global write
write:
 li a7, SYS_write
 2d2:	48c1                	li	a7,16
 ecall
 2d4:	00000073          	ecall
 ret
 2d8:	8082                	ret

00000000000002da <close>:
.global close
close:
 li a7, SYS_close
 2da:	48d5                	li	a7,21
 ecall
 2dc:	00000073          	ecall
 ret
 2e0:	8082                	ret

00000000000002e2 <kill>:
.global kill
kill:
 li a7, SYS_kill
 2e2:	4899                	li	a7,6
 ecall
 2e4:	00000073          	ecall
 ret
 2e8:	8082                	ret

00000000000002ea <exec>:
.global exec
exec:
 li a7, SYS_exec
 2ea:	489d                	li	a7,7
 ecall
 2ec:	00000073          	ecall
 ret
 2f0:	8082                	ret

00000000000002f2 <open>:
.global open
open:
 li a7, SYS_open
 2f2:	48bd                	li	a7,15
 ecall
 2f4:	00000073          	ecall
 ret
 2f8:	8082                	ret

00000000000002fa <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 2fa:	48c5                	li	a7,17
 ecall
 2fc:	00000073          	ecall
 ret
 300:	8082                	ret

0000000000000302 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 302:	48c9                	li	a7,18
 ecall
 304:	00000073          	ecall
 ret
 308:	8082                	ret

000000000000030a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 30a:	48a1                	li	a7,8
 ecall
 30c:	00000073          	ecall
 ret
 310:	8082                	ret

0000000000000312 <link>:
.global link
link:
 li a7, SYS_link
 312:	48cd                	li	a7,19
 ecall
 314:	00000073          	ecall
 ret
 318:	8082                	ret

000000000000031a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 31a:	48d1                	li	a7,20
 ecall
 31c:	00000073          	ecall
 ret
 320:	8082                	ret

0000000000000322 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 322:	48a5                	li	a7,9
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <dup>:
.global dup
dup:
 li a7, SYS_dup
 32a:	48a9                	li	a7,10
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 332:	48ad                	li	a7,11
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 33a:	48b1                	li	a7,12
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 342:	48b5                	li	a7,13
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 34a:	48b9                	li	a7,14
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 352:	48d9                	li	a7,22
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <getreadcount>:
.global getreadcount
getreadcount:
 li a7, SYS_getreadcount
 35a:	48dd                	li	a7,23
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 362:	48e1                	li	a7,24
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 36a:	1101                	addi	sp,sp,-32
 36c:	ec06                	sd	ra,24(sp)
 36e:	e822                	sd	s0,16(sp)
 370:	1000                	addi	s0,sp,32
 372:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 376:	4605                	li	a2,1
 378:	fef40593          	addi	a1,s0,-17
 37c:	00000097          	auipc	ra,0x0
 380:	f56080e7          	jalr	-170(ra) # 2d2 <write>
}
 384:	60e2                	ld	ra,24(sp)
 386:	6442                	ld	s0,16(sp)
 388:	6105                	addi	sp,sp,32
 38a:	8082                	ret

000000000000038c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 38c:	7139                	addi	sp,sp,-64
 38e:	fc06                	sd	ra,56(sp)
 390:	f822                	sd	s0,48(sp)
 392:	f426                	sd	s1,40(sp)
 394:	f04a                	sd	s2,32(sp)
 396:	ec4e                	sd	s3,24(sp)
 398:	0080                	addi	s0,sp,64
 39a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 39c:	c299                	beqz	a3,3a2 <printint+0x16>
 39e:	0805c963          	bltz	a1,430 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3a2:	2581                	sext.w	a1,a1
  neg = 0;
 3a4:	4881                	li	a7,0
 3a6:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3aa:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3ac:	2601                	sext.w	a2,a2
 3ae:	00000517          	auipc	a0,0x0
 3b2:	4c250513          	addi	a0,a0,1218 # 870 <digits>
 3b6:	883a                	mv	a6,a4
 3b8:	2705                	addiw	a4,a4,1
 3ba:	02c5f7bb          	remuw	a5,a1,a2
 3be:	1782                	slli	a5,a5,0x20
 3c0:	9381                	srli	a5,a5,0x20
 3c2:	97aa                	add	a5,a5,a0
 3c4:	0007c783          	lbu	a5,0(a5)
 3c8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3cc:	0005879b          	sext.w	a5,a1
 3d0:	02c5d5bb          	divuw	a1,a1,a2
 3d4:	0685                	addi	a3,a3,1
 3d6:	fec7f0e3          	bgeu	a5,a2,3b6 <printint+0x2a>
  if(neg)
 3da:	00088c63          	beqz	a7,3f2 <printint+0x66>
    buf[i++] = '-';
 3de:	fd070793          	addi	a5,a4,-48
 3e2:	00878733          	add	a4,a5,s0
 3e6:	02d00793          	li	a5,45
 3ea:	fef70823          	sb	a5,-16(a4)
 3ee:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 3f2:	02e05863          	blez	a4,422 <printint+0x96>
 3f6:	fc040793          	addi	a5,s0,-64
 3fa:	00e78933          	add	s2,a5,a4
 3fe:	fff78993          	addi	s3,a5,-1
 402:	99ba                	add	s3,s3,a4
 404:	377d                	addiw	a4,a4,-1
 406:	1702                	slli	a4,a4,0x20
 408:	9301                	srli	a4,a4,0x20
 40a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 40e:	fff94583          	lbu	a1,-1(s2)
 412:	8526                	mv	a0,s1
 414:	00000097          	auipc	ra,0x0
 418:	f56080e7          	jalr	-170(ra) # 36a <putc>
  while(--i >= 0)
 41c:	197d                	addi	s2,s2,-1
 41e:	ff3918e3          	bne	s2,s3,40e <printint+0x82>
}
 422:	70e2                	ld	ra,56(sp)
 424:	7442                	ld	s0,48(sp)
 426:	74a2                	ld	s1,40(sp)
 428:	7902                	ld	s2,32(sp)
 42a:	69e2                	ld	s3,24(sp)
 42c:	6121                	addi	sp,sp,64
 42e:	8082                	ret
    x = -xx;
 430:	40b005bb          	negw	a1,a1
    neg = 1;
 434:	4885                	li	a7,1
    x = -xx;
 436:	bf85                	j	3a6 <printint+0x1a>

0000000000000438 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 438:	7119                	addi	sp,sp,-128
 43a:	fc86                	sd	ra,120(sp)
 43c:	f8a2                	sd	s0,112(sp)
 43e:	f4a6                	sd	s1,104(sp)
 440:	f0ca                	sd	s2,96(sp)
 442:	ecce                	sd	s3,88(sp)
 444:	e8d2                	sd	s4,80(sp)
 446:	e4d6                	sd	s5,72(sp)
 448:	e0da                	sd	s6,64(sp)
 44a:	fc5e                	sd	s7,56(sp)
 44c:	f862                	sd	s8,48(sp)
 44e:	f466                	sd	s9,40(sp)
 450:	f06a                	sd	s10,32(sp)
 452:	ec6e                	sd	s11,24(sp)
 454:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 456:	0005c903          	lbu	s2,0(a1)
 45a:	18090f63          	beqz	s2,5f8 <vprintf+0x1c0>
 45e:	8aaa                	mv	s5,a0
 460:	8b32                	mv	s6,a2
 462:	00158493          	addi	s1,a1,1
  state = 0;
 466:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 468:	02500a13          	li	s4,37
 46c:	4c55                	li	s8,21
 46e:	00000c97          	auipc	s9,0x0
 472:	3aac8c93          	addi	s9,s9,938 # 818 <malloc+0x11c>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 476:	02800d93          	li	s11,40
  putc(fd, 'x');
 47a:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 47c:	00000b97          	auipc	s7,0x0
 480:	3f4b8b93          	addi	s7,s7,1012 # 870 <digits>
 484:	a839                	j	4a2 <vprintf+0x6a>
        putc(fd, c);
 486:	85ca                	mv	a1,s2
 488:	8556                	mv	a0,s5
 48a:	00000097          	auipc	ra,0x0
 48e:	ee0080e7          	jalr	-288(ra) # 36a <putc>
 492:	a019                	j	498 <vprintf+0x60>
    } else if(state == '%'){
 494:	01498d63          	beq	s3,s4,4ae <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 498:	0485                	addi	s1,s1,1
 49a:	fff4c903          	lbu	s2,-1(s1)
 49e:	14090d63          	beqz	s2,5f8 <vprintf+0x1c0>
    if(state == 0){
 4a2:	fe0999e3          	bnez	s3,494 <vprintf+0x5c>
      if(c == '%'){
 4a6:	ff4910e3          	bne	s2,s4,486 <vprintf+0x4e>
        state = '%';
 4aa:	89d2                	mv	s3,s4
 4ac:	b7f5                	j	498 <vprintf+0x60>
      if(c == 'd'){
 4ae:	11490c63          	beq	s2,s4,5c6 <vprintf+0x18e>
 4b2:	f9d9079b          	addiw	a5,s2,-99
 4b6:	0ff7f793          	zext.b	a5,a5
 4ba:	10fc6e63          	bltu	s8,a5,5d6 <vprintf+0x19e>
 4be:	f9d9079b          	addiw	a5,s2,-99
 4c2:	0ff7f713          	zext.b	a4,a5
 4c6:	10ec6863          	bltu	s8,a4,5d6 <vprintf+0x19e>
 4ca:	00271793          	slli	a5,a4,0x2
 4ce:	97e6                	add	a5,a5,s9
 4d0:	439c                	lw	a5,0(a5)
 4d2:	97e6                	add	a5,a5,s9
 4d4:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 4d6:	008b0913          	addi	s2,s6,8
 4da:	4685                	li	a3,1
 4dc:	4629                	li	a2,10
 4de:	000b2583          	lw	a1,0(s6)
 4e2:	8556                	mv	a0,s5
 4e4:	00000097          	auipc	ra,0x0
 4e8:	ea8080e7          	jalr	-344(ra) # 38c <printint>
 4ec:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 4ee:	4981                	li	s3,0
 4f0:	b765                	j	498 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4f2:	008b0913          	addi	s2,s6,8
 4f6:	4681                	li	a3,0
 4f8:	4629                	li	a2,10
 4fa:	000b2583          	lw	a1,0(s6)
 4fe:	8556                	mv	a0,s5
 500:	00000097          	auipc	ra,0x0
 504:	e8c080e7          	jalr	-372(ra) # 38c <printint>
 508:	8b4a                	mv	s6,s2
      state = 0;
 50a:	4981                	li	s3,0
 50c:	b771                	j	498 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 50e:	008b0913          	addi	s2,s6,8
 512:	4681                	li	a3,0
 514:	866a                	mv	a2,s10
 516:	000b2583          	lw	a1,0(s6)
 51a:	8556                	mv	a0,s5
 51c:	00000097          	auipc	ra,0x0
 520:	e70080e7          	jalr	-400(ra) # 38c <printint>
 524:	8b4a                	mv	s6,s2
      state = 0;
 526:	4981                	li	s3,0
 528:	bf85                	j	498 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 52a:	008b0793          	addi	a5,s6,8
 52e:	f8f43423          	sd	a5,-120(s0)
 532:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 536:	03000593          	li	a1,48
 53a:	8556                	mv	a0,s5
 53c:	00000097          	auipc	ra,0x0
 540:	e2e080e7          	jalr	-466(ra) # 36a <putc>
  putc(fd, 'x');
 544:	07800593          	li	a1,120
 548:	8556                	mv	a0,s5
 54a:	00000097          	auipc	ra,0x0
 54e:	e20080e7          	jalr	-480(ra) # 36a <putc>
 552:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 554:	03c9d793          	srli	a5,s3,0x3c
 558:	97de                	add	a5,a5,s7
 55a:	0007c583          	lbu	a1,0(a5)
 55e:	8556                	mv	a0,s5
 560:	00000097          	auipc	ra,0x0
 564:	e0a080e7          	jalr	-502(ra) # 36a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 568:	0992                	slli	s3,s3,0x4
 56a:	397d                	addiw	s2,s2,-1
 56c:	fe0914e3          	bnez	s2,554 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 570:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 574:	4981                	li	s3,0
 576:	b70d                	j	498 <vprintf+0x60>
        s = va_arg(ap, char*);
 578:	008b0913          	addi	s2,s6,8
 57c:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 580:	02098163          	beqz	s3,5a2 <vprintf+0x16a>
        while(*s != 0){
 584:	0009c583          	lbu	a1,0(s3)
 588:	c5ad                	beqz	a1,5f2 <vprintf+0x1ba>
          putc(fd, *s);
 58a:	8556                	mv	a0,s5
 58c:	00000097          	auipc	ra,0x0
 590:	dde080e7          	jalr	-546(ra) # 36a <putc>
          s++;
 594:	0985                	addi	s3,s3,1
        while(*s != 0){
 596:	0009c583          	lbu	a1,0(s3)
 59a:	f9e5                	bnez	a1,58a <vprintf+0x152>
        s = va_arg(ap, char*);
 59c:	8b4a                	mv	s6,s2
      state = 0;
 59e:	4981                	li	s3,0
 5a0:	bde5                	j	498 <vprintf+0x60>
          s = "(null)";
 5a2:	00000997          	auipc	s3,0x0
 5a6:	26e98993          	addi	s3,s3,622 # 810 <malloc+0x114>
        while(*s != 0){
 5aa:	85ee                	mv	a1,s11
 5ac:	bff9                	j	58a <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 5ae:	008b0913          	addi	s2,s6,8
 5b2:	000b4583          	lbu	a1,0(s6)
 5b6:	8556                	mv	a0,s5
 5b8:	00000097          	auipc	ra,0x0
 5bc:	db2080e7          	jalr	-590(ra) # 36a <putc>
 5c0:	8b4a                	mv	s6,s2
      state = 0;
 5c2:	4981                	li	s3,0
 5c4:	bdd1                	j	498 <vprintf+0x60>
        putc(fd, c);
 5c6:	85d2                	mv	a1,s4
 5c8:	8556                	mv	a0,s5
 5ca:	00000097          	auipc	ra,0x0
 5ce:	da0080e7          	jalr	-608(ra) # 36a <putc>
      state = 0;
 5d2:	4981                	li	s3,0
 5d4:	b5d1                	j	498 <vprintf+0x60>
        putc(fd, '%');
 5d6:	85d2                	mv	a1,s4
 5d8:	8556                	mv	a0,s5
 5da:	00000097          	auipc	ra,0x0
 5de:	d90080e7          	jalr	-624(ra) # 36a <putc>
        putc(fd, c);
 5e2:	85ca                	mv	a1,s2
 5e4:	8556                	mv	a0,s5
 5e6:	00000097          	auipc	ra,0x0
 5ea:	d84080e7          	jalr	-636(ra) # 36a <putc>
      state = 0;
 5ee:	4981                	li	s3,0
 5f0:	b565                	j	498 <vprintf+0x60>
        s = va_arg(ap, char*);
 5f2:	8b4a                	mv	s6,s2
      state = 0;
 5f4:	4981                	li	s3,0
 5f6:	b54d                	j	498 <vprintf+0x60>
    }
  }
}
 5f8:	70e6                	ld	ra,120(sp)
 5fa:	7446                	ld	s0,112(sp)
 5fc:	74a6                	ld	s1,104(sp)
 5fe:	7906                	ld	s2,96(sp)
 600:	69e6                	ld	s3,88(sp)
 602:	6a46                	ld	s4,80(sp)
 604:	6aa6                	ld	s5,72(sp)
 606:	6b06                	ld	s6,64(sp)
 608:	7be2                	ld	s7,56(sp)
 60a:	7c42                	ld	s8,48(sp)
 60c:	7ca2                	ld	s9,40(sp)
 60e:	7d02                	ld	s10,32(sp)
 610:	6de2                	ld	s11,24(sp)
 612:	6109                	addi	sp,sp,128
 614:	8082                	ret

0000000000000616 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 616:	715d                	addi	sp,sp,-80
 618:	ec06                	sd	ra,24(sp)
 61a:	e822                	sd	s0,16(sp)
 61c:	1000                	addi	s0,sp,32
 61e:	e010                	sd	a2,0(s0)
 620:	e414                	sd	a3,8(s0)
 622:	e818                	sd	a4,16(s0)
 624:	ec1c                	sd	a5,24(s0)
 626:	03043023          	sd	a6,32(s0)
 62a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 62e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 632:	8622                	mv	a2,s0
 634:	00000097          	auipc	ra,0x0
 638:	e04080e7          	jalr	-508(ra) # 438 <vprintf>
}
 63c:	60e2                	ld	ra,24(sp)
 63e:	6442                	ld	s0,16(sp)
 640:	6161                	addi	sp,sp,80
 642:	8082                	ret

0000000000000644 <printf>:

void
printf(const char *fmt, ...)
{
 644:	711d                	addi	sp,sp,-96
 646:	ec06                	sd	ra,24(sp)
 648:	e822                	sd	s0,16(sp)
 64a:	1000                	addi	s0,sp,32
 64c:	e40c                	sd	a1,8(s0)
 64e:	e810                	sd	a2,16(s0)
 650:	ec14                	sd	a3,24(s0)
 652:	f018                	sd	a4,32(s0)
 654:	f41c                	sd	a5,40(s0)
 656:	03043823          	sd	a6,48(s0)
 65a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 65e:	00840613          	addi	a2,s0,8
 662:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 666:	85aa                	mv	a1,a0
 668:	4505                	li	a0,1
 66a:	00000097          	auipc	ra,0x0
 66e:	dce080e7          	jalr	-562(ra) # 438 <vprintf>
}
 672:	60e2                	ld	ra,24(sp)
 674:	6442                	ld	s0,16(sp)
 676:	6125                	addi	sp,sp,96
 678:	8082                	ret

000000000000067a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 67a:	1141                	addi	sp,sp,-16
 67c:	e422                	sd	s0,8(sp)
 67e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 680:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 684:	00001797          	auipc	a5,0x1
 688:	97c7b783          	ld	a5,-1668(a5) # 1000 <freep>
 68c:	a02d                	j	6b6 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 68e:	4618                	lw	a4,8(a2)
 690:	9f2d                	addw	a4,a4,a1
 692:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 696:	6398                	ld	a4,0(a5)
 698:	6310                	ld	a2,0(a4)
 69a:	a83d                	j	6d8 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 69c:	ff852703          	lw	a4,-8(a0)
 6a0:	9f31                	addw	a4,a4,a2
 6a2:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6a4:	ff053683          	ld	a3,-16(a0)
 6a8:	a091                	j	6ec <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6aa:	6398                	ld	a4,0(a5)
 6ac:	00e7e463          	bltu	a5,a4,6b4 <free+0x3a>
 6b0:	00e6ea63          	bltu	a3,a4,6c4 <free+0x4a>
{
 6b4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6b6:	fed7fae3          	bgeu	a5,a3,6aa <free+0x30>
 6ba:	6398                	ld	a4,0(a5)
 6bc:	00e6e463          	bltu	a3,a4,6c4 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6c0:	fee7eae3          	bltu	a5,a4,6b4 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 6c4:	ff852583          	lw	a1,-8(a0)
 6c8:	6390                	ld	a2,0(a5)
 6ca:	02059813          	slli	a6,a1,0x20
 6ce:	01c85713          	srli	a4,a6,0x1c
 6d2:	9736                	add	a4,a4,a3
 6d4:	fae60de3          	beq	a2,a4,68e <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 6d8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6dc:	4790                	lw	a2,8(a5)
 6de:	02061593          	slli	a1,a2,0x20
 6e2:	01c5d713          	srli	a4,a1,0x1c
 6e6:	973e                	add	a4,a4,a5
 6e8:	fae68ae3          	beq	a3,a4,69c <free+0x22>
    p->s.ptr = bp->s.ptr;
 6ec:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 6ee:	00001717          	auipc	a4,0x1
 6f2:	90f73923          	sd	a5,-1774(a4) # 1000 <freep>
}
 6f6:	6422                	ld	s0,8(sp)
 6f8:	0141                	addi	sp,sp,16
 6fa:	8082                	ret

00000000000006fc <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6fc:	7139                	addi	sp,sp,-64
 6fe:	fc06                	sd	ra,56(sp)
 700:	f822                	sd	s0,48(sp)
 702:	f426                	sd	s1,40(sp)
 704:	f04a                	sd	s2,32(sp)
 706:	ec4e                	sd	s3,24(sp)
 708:	e852                	sd	s4,16(sp)
 70a:	e456                	sd	s5,8(sp)
 70c:	e05a                	sd	s6,0(sp)
 70e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 710:	02051493          	slli	s1,a0,0x20
 714:	9081                	srli	s1,s1,0x20
 716:	04bd                	addi	s1,s1,15
 718:	8091                	srli	s1,s1,0x4
 71a:	0014899b          	addiw	s3,s1,1
 71e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 720:	00001517          	auipc	a0,0x1
 724:	8e053503          	ld	a0,-1824(a0) # 1000 <freep>
 728:	c515                	beqz	a0,754 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 72a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 72c:	4798                	lw	a4,8(a5)
 72e:	02977f63          	bgeu	a4,s1,76c <malloc+0x70>
 732:	8a4e                	mv	s4,s3
 734:	0009871b          	sext.w	a4,s3
 738:	6685                	lui	a3,0x1
 73a:	00d77363          	bgeu	a4,a3,740 <malloc+0x44>
 73e:	6a05                	lui	s4,0x1
 740:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 744:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 748:	00001917          	auipc	s2,0x1
 74c:	8b890913          	addi	s2,s2,-1864 # 1000 <freep>
  if(p == (char*)-1)
 750:	5afd                	li	s5,-1
 752:	a895                	j	7c6 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 754:	00001797          	auipc	a5,0x1
 758:	8bc78793          	addi	a5,a5,-1860 # 1010 <base>
 75c:	00001717          	auipc	a4,0x1
 760:	8af73223          	sd	a5,-1884(a4) # 1000 <freep>
 764:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 766:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 76a:	b7e1                	j	732 <malloc+0x36>
      if(p->s.size == nunits)
 76c:	02e48c63          	beq	s1,a4,7a4 <malloc+0xa8>
        p->s.size -= nunits;
 770:	4137073b          	subw	a4,a4,s3
 774:	c798                	sw	a4,8(a5)
        p += p->s.size;
 776:	02071693          	slli	a3,a4,0x20
 77a:	01c6d713          	srli	a4,a3,0x1c
 77e:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 780:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 784:	00001717          	auipc	a4,0x1
 788:	86a73e23          	sd	a0,-1924(a4) # 1000 <freep>
      return (void*)(p + 1);
 78c:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 790:	70e2                	ld	ra,56(sp)
 792:	7442                	ld	s0,48(sp)
 794:	74a2                	ld	s1,40(sp)
 796:	7902                	ld	s2,32(sp)
 798:	69e2                	ld	s3,24(sp)
 79a:	6a42                	ld	s4,16(sp)
 79c:	6aa2                	ld	s5,8(sp)
 79e:	6b02                	ld	s6,0(sp)
 7a0:	6121                	addi	sp,sp,64
 7a2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7a4:	6398                	ld	a4,0(a5)
 7a6:	e118                	sd	a4,0(a0)
 7a8:	bff1                	j	784 <malloc+0x88>
  hp->s.size = nu;
 7aa:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7ae:	0541                	addi	a0,a0,16
 7b0:	00000097          	auipc	ra,0x0
 7b4:	eca080e7          	jalr	-310(ra) # 67a <free>
  return freep;
 7b8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7bc:	d971                	beqz	a0,790 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7be:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7c0:	4798                	lw	a4,8(a5)
 7c2:	fa9775e3          	bgeu	a4,s1,76c <malloc+0x70>
    if(p == freep)
 7c6:	00093703          	ld	a4,0(s2)
 7ca:	853e                	mv	a0,a5
 7cc:	fef719e3          	bne	a4,a5,7be <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 7d0:	8552                	mv	a0,s4
 7d2:	00000097          	auipc	ra,0x0
 7d6:	b68080e7          	jalr	-1176(ra) # 33a <sbrk>
  if(p == (char*)-1)
 7da:	fd5518e3          	bne	a0,s5,7aa <malloc+0xae>
        return 0;
 7de:	4501                	li	a0,0
 7e0:	bf45                	j	790 <malloc+0x94>
