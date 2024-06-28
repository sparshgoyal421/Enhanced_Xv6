
user/_schedulertest:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:

#define NFORK 10
#define IO 4

int main()
{
   0:	715d                	addi	sp,sp,-80
   2:	e486                	sd	ra,72(sp)
   4:	e0a2                	sd	s0,64(sp)
   6:	fc26                	sd	s1,56(sp)
   8:	f84a                	sd	s2,48(sp)
   a:	f44e                	sd	s3,40(sp)
   c:	f052                	sd	s4,32(sp)
   e:	ec56                	sd	s5,24(sp)
  10:	e85a                	sd	s6,16(sp)
  12:	0880                	addi	s0,sp,80
  int n, pid;
  int wtime, rtime;
  int twtime = 0, trtime = 0;
  for (n = 0; n < NFORK; n++)
  14:	02e00993          	li	s3,46
  18:	4481                	li	s1,0
{
  1a:	05f5eab7          	lui	s5,0x5f5e
  1e:	100a8a93          	addi	s5,s5,256 # 5f5e100 <base+0x5f5d0f0>
  for (n = 0; n < NFORK; n++)
  22:	4b29                	li	s6,10
  24:	a025                	j	4c <main+0x4c>
    {
    };
    pid = fork();
#ifdef PBS
    if (pid != 0)
      set_priority(pid, 50 - IO + n); // Will only matter for PBS, set lower priority for IO bound processes
  26:	00098a1b          	sext.w	s4,s3
  2a:	85d2                	mv	a1,s4
  2c:	00000097          	auipc	ra,0x0
  30:	414080e7          	jalr	1044(ra) # 440 <set_priority>
#endif
    if (pid < 0)
  34:	02094f63          	bltz	s2,72 <main+0x72>
      exit(0);
    }
    else
    {
#ifdef PBS
      set_priority(pid,50 - IO + n); // Will only matter for PBS, set lower priority for IO bound processes
  38:	85d2                	mv	a1,s4
  3a:	854a                	mv	a0,s2
  3c:	00000097          	auipc	ra,0x0
  40:	404080e7          	jalr	1028(ra) # 440 <set_priority>
  for (n = 0; n < NFORK; n++)
  44:	2485                	addiw	s1,s1,1
  46:	2985                	addiw	s3,s3,1
  48:	05648063          	beq	s1,s6,88 <main+0x88>
{
  4c:	87d6                	mv	a5,s5
    for (int j = 0; j < 100000000; ++j)
  4e:	37fd                	addiw	a5,a5,-1
  50:	fffd                	bnez	a5,4e <main+0x4e>
    pid = fork();
  52:	00000097          	auipc	ra,0x0
  56:	336080e7          	jalr	822(ra) # 388 <fork>
  5a:	892a                	mv	s2,a0
    if (pid != 0)
  5c:	f569                	bnez	a0,26 <main+0x26>
      if (n < IO)
  5e:	478d                	li	a5,3
  60:	0497db63          	bge	a5,s1,b6 <main+0xb6>
  64:	800007b7          	lui	a5,0x80000
  68:	fff7c793          	not	a5,a5
        for (uint64 i = 0; i < n * 1000000000; i++)
  6c:	17fd                	addi	a5,a5,-1 # ffffffff7fffffff <base+0xffffffff7fffefef>
  6e:	fffd                	bnez	a5,6c <main+0x6c>
  70:	a889                	j	c2 <main+0xc2>
      printf("ERR %d\n", n);
  72:	85a6                	mv	a1,s1
  74:	00001517          	auipc	a0,0x1
  78:	84c50513          	addi	a0,a0,-1972 # 8c0 <malloc+0xe6>
  7c:	00000097          	auipc	ra,0x0
  80:	6a6080e7          	jalr	1702(ra) # 722 <printf>
#endif
    };
  }
  for (; n > 0; n--)
  84:	00905563          	blez	s1,8e <main+0x8e>
  for (n = 0; n < NFORK; n++)
  88:	4901                	li	s2,0
  8a:	4981                	li	s3,0
  8c:	a899                	j	e2 <main+0xe2>
  for (; n > 0; n--)
  8e:	4901                	li	s2,0
  90:	4981                	li	s3,0
    {
      trtime += rtime;
      twtime += wtime;
    }
  }
  printf("Average rtime %d,  wtime %d\n", trtime / NFORK, twtime / NFORK);
  92:	45a9                	li	a1,10
  94:	02b9c63b          	divw	a2,s3,a1
  98:	02b945bb          	divw	a1,s2,a1
  9c:	00001517          	auipc	a0,0x1
  a0:	84450513          	addi	a0,a0,-1980 # 8e0 <malloc+0x106>
  a4:	00000097          	auipc	ra,0x0
  a8:	67e080e7          	jalr	1662(ra) # 722 <printf>
  exit(0);
  ac:	4501                	li	a0,0
  ae:	00000097          	auipc	ra,0x0
  b2:	2e2080e7          	jalr	738(ra) # 390 <exit>
        sleep(200); // IO bound processes
  b6:	0c800513          	li	a0,200
  ba:	00000097          	auipc	ra,0x0
  be:	366080e7          	jalr	870(ra) # 420 <sleep>
      printf("Process %d finished\n", n);
  c2:	85a6                	mv	a1,s1
  c4:	00001517          	auipc	a0,0x1
  c8:	80450513          	addi	a0,a0,-2044 # 8c8 <malloc+0xee>
  cc:	00000097          	auipc	ra,0x0
  d0:	656080e7          	jalr	1622(ra) # 722 <printf>
      exit(0);
  d4:	4501                	li	a0,0
  d6:	00000097          	auipc	ra,0x0
  da:	2ba080e7          	jalr	698(ra) # 390 <exit>
  for (; n > 0; n--)
  de:	34fd                	addiw	s1,s1,-1
  e0:	d8cd                	beqz	s1,92 <main+0x92>
    if (waitx(0, &wtime, &rtime) >= 0)
  e2:	fb840613          	addi	a2,s0,-72
  e6:	fbc40593          	addi	a1,s0,-68
  ea:	4501                	li	a0,0
  ec:	00000097          	auipc	ra,0x0
  f0:	344080e7          	jalr	836(ra) # 430 <waitx>
  f4:	fe0545e3          	bltz	a0,de <main+0xde>
      trtime += rtime;
  f8:	fb842783          	lw	a5,-72(s0)
  fc:	0127893b          	addw	s2,a5,s2
      twtime += wtime;
 100:	fbc42783          	lw	a5,-68(s0)
 104:	013789bb          	addw	s3,a5,s3
 108:	bfd9                	j	de <main+0xde>

000000000000010a <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 10a:	1141                	addi	sp,sp,-16
 10c:	e406                	sd	ra,8(sp)
 10e:	e022                	sd	s0,0(sp)
 110:	0800                	addi	s0,sp,16
  extern int main();
  main();
 112:	00000097          	auipc	ra,0x0
 116:	eee080e7          	jalr	-274(ra) # 0 <main>
  exit(0);
 11a:	4501                	li	a0,0
 11c:	00000097          	auipc	ra,0x0
 120:	274080e7          	jalr	628(ra) # 390 <exit>

0000000000000124 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 124:	1141                	addi	sp,sp,-16
 126:	e422                	sd	s0,8(sp)
 128:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 12a:	87aa                	mv	a5,a0
 12c:	0585                	addi	a1,a1,1
 12e:	0785                	addi	a5,a5,1
 130:	fff5c703          	lbu	a4,-1(a1)
 134:	fee78fa3          	sb	a4,-1(a5)
 138:	fb75                	bnez	a4,12c <strcpy+0x8>
    ;
  return os;
}
 13a:	6422                	ld	s0,8(sp)
 13c:	0141                	addi	sp,sp,16
 13e:	8082                	ret

0000000000000140 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 140:	1141                	addi	sp,sp,-16
 142:	e422                	sd	s0,8(sp)
 144:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 146:	00054783          	lbu	a5,0(a0)
 14a:	cb91                	beqz	a5,15e <strcmp+0x1e>
 14c:	0005c703          	lbu	a4,0(a1)
 150:	00f71763          	bne	a4,a5,15e <strcmp+0x1e>
    p++, q++;
 154:	0505                	addi	a0,a0,1
 156:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 158:	00054783          	lbu	a5,0(a0)
 15c:	fbe5                	bnez	a5,14c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 15e:	0005c503          	lbu	a0,0(a1)
}
 162:	40a7853b          	subw	a0,a5,a0
 166:	6422                	ld	s0,8(sp)
 168:	0141                	addi	sp,sp,16
 16a:	8082                	ret

000000000000016c <strlen>:

uint
strlen(const char *s)
{
 16c:	1141                	addi	sp,sp,-16
 16e:	e422                	sd	s0,8(sp)
 170:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 172:	00054783          	lbu	a5,0(a0)
 176:	cf91                	beqz	a5,192 <strlen+0x26>
 178:	0505                	addi	a0,a0,1
 17a:	87aa                	mv	a5,a0
 17c:	4685                	li	a3,1
 17e:	9e89                	subw	a3,a3,a0
 180:	00f6853b          	addw	a0,a3,a5
 184:	0785                	addi	a5,a5,1
 186:	fff7c703          	lbu	a4,-1(a5)
 18a:	fb7d                	bnez	a4,180 <strlen+0x14>
    ;
  return n;
}
 18c:	6422                	ld	s0,8(sp)
 18e:	0141                	addi	sp,sp,16
 190:	8082                	ret
  for(n = 0; s[n]; n++)
 192:	4501                	li	a0,0
 194:	bfe5                	j	18c <strlen+0x20>

0000000000000196 <memset>:

void*
memset(void *dst, int c, uint n)
{
 196:	1141                	addi	sp,sp,-16
 198:	e422                	sd	s0,8(sp)
 19a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 19c:	ca19                	beqz	a2,1b2 <memset+0x1c>
 19e:	87aa                	mv	a5,a0
 1a0:	1602                	slli	a2,a2,0x20
 1a2:	9201                	srli	a2,a2,0x20
 1a4:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 1a8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1ac:	0785                	addi	a5,a5,1
 1ae:	fee79de3          	bne	a5,a4,1a8 <memset+0x12>
  }
  return dst;
}
 1b2:	6422                	ld	s0,8(sp)
 1b4:	0141                	addi	sp,sp,16
 1b6:	8082                	ret

00000000000001b8 <strchr>:

char*
strchr(const char *s, char c)
{
 1b8:	1141                	addi	sp,sp,-16
 1ba:	e422                	sd	s0,8(sp)
 1bc:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1be:	00054783          	lbu	a5,0(a0)
 1c2:	cb99                	beqz	a5,1d8 <strchr+0x20>
    if(*s == c)
 1c4:	00f58763          	beq	a1,a5,1d2 <strchr+0x1a>
  for(; *s; s++)
 1c8:	0505                	addi	a0,a0,1
 1ca:	00054783          	lbu	a5,0(a0)
 1ce:	fbfd                	bnez	a5,1c4 <strchr+0xc>
      return (char*)s;
  return 0;
 1d0:	4501                	li	a0,0
}
 1d2:	6422                	ld	s0,8(sp)
 1d4:	0141                	addi	sp,sp,16
 1d6:	8082                	ret
  return 0;
 1d8:	4501                	li	a0,0
 1da:	bfe5                	j	1d2 <strchr+0x1a>

00000000000001dc <gets>:

char*
gets(char *buf, int max)
{
 1dc:	711d                	addi	sp,sp,-96
 1de:	ec86                	sd	ra,88(sp)
 1e0:	e8a2                	sd	s0,80(sp)
 1e2:	e4a6                	sd	s1,72(sp)
 1e4:	e0ca                	sd	s2,64(sp)
 1e6:	fc4e                	sd	s3,56(sp)
 1e8:	f852                	sd	s4,48(sp)
 1ea:	f456                	sd	s5,40(sp)
 1ec:	f05a                	sd	s6,32(sp)
 1ee:	ec5e                	sd	s7,24(sp)
 1f0:	1080                	addi	s0,sp,96
 1f2:	8baa                	mv	s7,a0
 1f4:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1f6:	892a                	mv	s2,a0
 1f8:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1fa:	4aa9                	li	s5,10
 1fc:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1fe:	89a6                	mv	s3,s1
 200:	2485                	addiw	s1,s1,1
 202:	0344d863          	bge	s1,s4,232 <gets+0x56>
    cc = read(0, &c, 1);
 206:	4605                	li	a2,1
 208:	faf40593          	addi	a1,s0,-81
 20c:	4501                	li	a0,0
 20e:	00000097          	auipc	ra,0x0
 212:	19a080e7          	jalr	410(ra) # 3a8 <read>
    if(cc < 1)
 216:	00a05e63          	blez	a0,232 <gets+0x56>
    buf[i++] = c;
 21a:	faf44783          	lbu	a5,-81(s0)
 21e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 222:	01578763          	beq	a5,s5,230 <gets+0x54>
 226:	0905                	addi	s2,s2,1
 228:	fd679be3          	bne	a5,s6,1fe <gets+0x22>
  for(i=0; i+1 < max; ){
 22c:	89a6                	mv	s3,s1
 22e:	a011                	j	232 <gets+0x56>
 230:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 232:	99de                	add	s3,s3,s7
 234:	00098023          	sb	zero,0(s3)
  return buf;
}
 238:	855e                	mv	a0,s7
 23a:	60e6                	ld	ra,88(sp)
 23c:	6446                	ld	s0,80(sp)
 23e:	64a6                	ld	s1,72(sp)
 240:	6906                	ld	s2,64(sp)
 242:	79e2                	ld	s3,56(sp)
 244:	7a42                	ld	s4,48(sp)
 246:	7aa2                	ld	s5,40(sp)
 248:	7b02                	ld	s6,32(sp)
 24a:	6be2                	ld	s7,24(sp)
 24c:	6125                	addi	sp,sp,96
 24e:	8082                	ret

0000000000000250 <stat>:

int
stat(const char *n, struct stat *st)
{
 250:	1101                	addi	sp,sp,-32
 252:	ec06                	sd	ra,24(sp)
 254:	e822                	sd	s0,16(sp)
 256:	e426                	sd	s1,8(sp)
 258:	e04a                	sd	s2,0(sp)
 25a:	1000                	addi	s0,sp,32
 25c:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 25e:	4581                	li	a1,0
 260:	00000097          	auipc	ra,0x0
 264:	170080e7          	jalr	368(ra) # 3d0 <open>
  if(fd < 0)
 268:	02054563          	bltz	a0,292 <stat+0x42>
 26c:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 26e:	85ca                	mv	a1,s2
 270:	00000097          	auipc	ra,0x0
 274:	178080e7          	jalr	376(ra) # 3e8 <fstat>
 278:	892a                	mv	s2,a0
  close(fd);
 27a:	8526                	mv	a0,s1
 27c:	00000097          	auipc	ra,0x0
 280:	13c080e7          	jalr	316(ra) # 3b8 <close>
  return r;
}
 284:	854a                	mv	a0,s2
 286:	60e2                	ld	ra,24(sp)
 288:	6442                	ld	s0,16(sp)
 28a:	64a2                	ld	s1,8(sp)
 28c:	6902                	ld	s2,0(sp)
 28e:	6105                	addi	sp,sp,32
 290:	8082                	ret
    return -1;
 292:	597d                	li	s2,-1
 294:	bfc5                	j	284 <stat+0x34>

0000000000000296 <atoi>:

int
atoi(const char *s)
{
 296:	1141                	addi	sp,sp,-16
 298:	e422                	sd	s0,8(sp)
 29a:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 29c:	00054683          	lbu	a3,0(a0)
 2a0:	fd06879b          	addiw	a5,a3,-48
 2a4:	0ff7f793          	zext.b	a5,a5
 2a8:	4625                	li	a2,9
 2aa:	02f66863          	bltu	a2,a5,2da <atoi+0x44>
 2ae:	872a                	mv	a4,a0
  n = 0;
 2b0:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 2b2:	0705                	addi	a4,a4,1
 2b4:	0025179b          	slliw	a5,a0,0x2
 2b8:	9fa9                	addw	a5,a5,a0
 2ba:	0017979b          	slliw	a5,a5,0x1
 2be:	9fb5                	addw	a5,a5,a3
 2c0:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2c4:	00074683          	lbu	a3,0(a4)
 2c8:	fd06879b          	addiw	a5,a3,-48
 2cc:	0ff7f793          	zext.b	a5,a5
 2d0:	fef671e3          	bgeu	a2,a5,2b2 <atoi+0x1c>
  return n;
}
 2d4:	6422                	ld	s0,8(sp)
 2d6:	0141                	addi	sp,sp,16
 2d8:	8082                	ret
  n = 0;
 2da:	4501                	li	a0,0
 2dc:	bfe5                	j	2d4 <atoi+0x3e>

00000000000002de <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2de:	1141                	addi	sp,sp,-16
 2e0:	e422                	sd	s0,8(sp)
 2e2:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2e4:	02b57463          	bgeu	a0,a1,30c <memmove+0x2e>
    while(n-- > 0)
 2e8:	00c05f63          	blez	a2,306 <memmove+0x28>
 2ec:	1602                	slli	a2,a2,0x20
 2ee:	9201                	srli	a2,a2,0x20
 2f0:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2f4:	872a                	mv	a4,a0
      *dst++ = *src++;
 2f6:	0585                	addi	a1,a1,1
 2f8:	0705                	addi	a4,a4,1
 2fa:	fff5c683          	lbu	a3,-1(a1)
 2fe:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 302:	fee79ae3          	bne	a5,a4,2f6 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 306:	6422                	ld	s0,8(sp)
 308:	0141                	addi	sp,sp,16
 30a:	8082                	ret
    dst += n;
 30c:	00c50733          	add	a4,a0,a2
    src += n;
 310:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 312:	fec05ae3          	blez	a2,306 <memmove+0x28>
 316:	fff6079b          	addiw	a5,a2,-1
 31a:	1782                	slli	a5,a5,0x20
 31c:	9381                	srli	a5,a5,0x20
 31e:	fff7c793          	not	a5,a5
 322:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 324:	15fd                	addi	a1,a1,-1
 326:	177d                	addi	a4,a4,-1
 328:	0005c683          	lbu	a3,0(a1)
 32c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 330:	fee79ae3          	bne	a5,a4,324 <memmove+0x46>
 334:	bfc9                	j	306 <memmove+0x28>

0000000000000336 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 336:	1141                	addi	sp,sp,-16
 338:	e422                	sd	s0,8(sp)
 33a:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 33c:	ca05                	beqz	a2,36c <memcmp+0x36>
 33e:	fff6069b          	addiw	a3,a2,-1
 342:	1682                	slli	a3,a3,0x20
 344:	9281                	srli	a3,a3,0x20
 346:	0685                	addi	a3,a3,1
 348:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 34a:	00054783          	lbu	a5,0(a0)
 34e:	0005c703          	lbu	a4,0(a1)
 352:	00e79863          	bne	a5,a4,362 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 356:	0505                	addi	a0,a0,1
    p2++;
 358:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 35a:	fed518e3          	bne	a0,a3,34a <memcmp+0x14>
  }
  return 0;
 35e:	4501                	li	a0,0
 360:	a019                	j	366 <memcmp+0x30>
      return *p1 - *p2;
 362:	40e7853b          	subw	a0,a5,a4
}
 366:	6422                	ld	s0,8(sp)
 368:	0141                	addi	sp,sp,16
 36a:	8082                	ret
  return 0;
 36c:	4501                	li	a0,0
 36e:	bfe5                	j	366 <memcmp+0x30>

0000000000000370 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 370:	1141                	addi	sp,sp,-16
 372:	e406                	sd	ra,8(sp)
 374:	e022                	sd	s0,0(sp)
 376:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 378:	00000097          	auipc	ra,0x0
 37c:	f66080e7          	jalr	-154(ra) # 2de <memmove>
}
 380:	60a2                	ld	ra,8(sp)
 382:	6402                	ld	s0,0(sp)
 384:	0141                	addi	sp,sp,16
 386:	8082                	ret

0000000000000388 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 388:	4885                	li	a7,1
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <exit>:
.global exit
exit:
 li a7, SYS_exit
 390:	4889                	li	a7,2
 ecall
 392:	00000073          	ecall
 ret
 396:	8082                	ret

0000000000000398 <wait>:
.global wait
wait:
 li a7, SYS_wait
 398:	488d                	li	a7,3
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3a0:	4891                	li	a7,4
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <read>:
.global read
read:
 li a7, SYS_read
 3a8:	4895                	li	a7,5
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <write>:
.global write
write:
 li a7, SYS_write
 3b0:	48c1                	li	a7,16
 ecall
 3b2:	00000073          	ecall
 ret
 3b6:	8082                	ret

00000000000003b8 <close>:
.global close
close:
 li a7, SYS_close
 3b8:	48d5                	li	a7,21
 ecall
 3ba:	00000073          	ecall
 ret
 3be:	8082                	ret

00000000000003c0 <kill>:
.global kill
kill:
 li a7, SYS_kill
 3c0:	4899                	li	a7,6
 ecall
 3c2:	00000073          	ecall
 ret
 3c6:	8082                	ret

00000000000003c8 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3c8:	489d                	li	a7,7
 ecall
 3ca:	00000073          	ecall
 ret
 3ce:	8082                	ret

00000000000003d0 <open>:
.global open
open:
 li a7, SYS_open
 3d0:	48bd                	li	a7,15
 ecall
 3d2:	00000073          	ecall
 ret
 3d6:	8082                	ret

00000000000003d8 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3d8:	48c5                	li	a7,17
 ecall
 3da:	00000073          	ecall
 ret
 3de:	8082                	ret

00000000000003e0 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3e0:	48c9                	li	a7,18
 ecall
 3e2:	00000073          	ecall
 ret
 3e6:	8082                	ret

00000000000003e8 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3e8:	48a1                	li	a7,8
 ecall
 3ea:	00000073          	ecall
 ret
 3ee:	8082                	ret

00000000000003f0 <link>:
.global link
link:
 li a7, SYS_link
 3f0:	48cd                	li	a7,19
 ecall
 3f2:	00000073          	ecall
 ret
 3f6:	8082                	ret

00000000000003f8 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3f8:	48d1                	li	a7,20
 ecall
 3fa:	00000073          	ecall
 ret
 3fe:	8082                	ret

0000000000000400 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 400:	48a5                	li	a7,9
 ecall
 402:	00000073          	ecall
 ret
 406:	8082                	ret

0000000000000408 <dup>:
.global dup
dup:
 li a7, SYS_dup
 408:	48a9                	li	a7,10
 ecall
 40a:	00000073          	ecall
 ret
 40e:	8082                	ret

0000000000000410 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 410:	48ad                	li	a7,11
 ecall
 412:	00000073          	ecall
 ret
 416:	8082                	ret

0000000000000418 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 418:	48b1                	li	a7,12
 ecall
 41a:	00000073          	ecall
 ret
 41e:	8082                	ret

0000000000000420 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 420:	48b5                	li	a7,13
 ecall
 422:	00000073          	ecall
 ret
 426:	8082                	ret

0000000000000428 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 428:	48b9                	li	a7,14
 ecall
 42a:	00000073          	ecall
 ret
 42e:	8082                	ret

0000000000000430 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 430:	48d9                	li	a7,22
 ecall
 432:	00000073          	ecall
 ret
 436:	8082                	ret

0000000000000438 <getreadcount>:
.global getreadcount
getreadcount:
 li a7, SYS_getreadcount
 438:	48dd                	li	a7,23
 ecall
 43a:	00000073          	ecall
 ret
 43e:	8082                	ret

0000000000000440 <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 440:	48e1                	li	a7,24
 ecall
 442:	00000073          	ecall
 ret
 446:	8082                	ret

0000000000000448 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 448:	1101                	addi	sp,sp,-32
 44a:	ec06                	sd	ra,24(sp)
 44c:	e822                	sd	s0,16(sp)
 44e:	1000                	addi	s0,sp,32
 450:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 454:	4605                	li	a2,1
 456:	fef40593          	addi	a1,s0,-17
 45a:	00000097          	auipc	ra,0x0
 45e:	f56080e7          	jalr	-170(ra) # 3b0 <write>
}
 462:	60e2                	ld	ra,24(sp)
 464:	6442                	ld	s0,16(sp)
 466:	6105                	addi	sp,sp,32
 468:	8082                	ret

000000000000046a <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 46a:	7139                	addi	sp,sp,-64
 46c:	fc06                	sd	ra,56(sp)
 46e:	f822                	sd	s0,48(sp)
 470:	f426                	sd	s1,40(sp)
 472:	f04a                	sd	s2,32(sp)
 474:	ec4e                	sd	s3,24(sp)
 476:	0080                	addi	s0,sp,64
 478:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 47a:	c299                	beqz	a3,480 <printint+0x16>
 47c:	0805c963          	bltz	a1,50e <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 480:	2581                	sext.w	a1,a1
  neg = 0;
 482:	4881                	li	a7,0
 484:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 488:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 48a:	2601                	sext.w	a2,a2
 48c:	00000517          	auipc	a0,0x0
 490:	4d450513          	addi	a0,a0,1236 # 960 <digits>
 494:	883a                	mv	a6,a4
 496:	2705                	addiw	a4,a4,1
 498:	02c5f7bb          	remuw	a5,a1,a2
 49c:	1782                	slli	a5,a5,0x20
 49e:	9381                	srli	a5,a5,0x20
 4a0:	97aa                	add	a5,a5,a0
 4a2:	0007c783          	lbu	a5,0(a5)
 4a6:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4aa:	0005879b          	sext.w	a5,a1
 4ae:	02c5d5bb          	divuw	a1,a1,a2
 4b2:	0685                	addi	a3,a3,1
 4b4:	fec7f0e3          	bgeu	a5,a2,494 <printint+0x2a>
  if(neg)
 4b8:	00088c63          	beqz	a7,4d0 <printint+0x66>
    buf[i++] = '-';
 4bc:	fd070793          	addi	a5,a4,-48
 4c0:	00878733          	add	a4,a5,s0
 4c4:	02d00793          	li	a5,45
 4c8:	fef70823          	sb	a5,-16(a4)
 4cc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4d0:	02e05863          	blez	a4,500 <printint+0x96>
 4d4:	fc040793          	addi	a5,s0,-64
 4d8:	00e78933          	add	s2,a5,a4
 4dc:	fff78993          	addi	s3,a5,-1
 4e0:	99ba                	add	s3,s3,a4
 4e2:	377d                	addiw	a4,a4,-1
 4e4:	1702                	slli	a4,a4,0x20
 4e6:	9301                	srli	a4,a4,0x20
 4e8:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 4ec:	fff94583          	lbu	a1,-1(s2)
 4f0:	8526                	mv	a0,s1
 4f2:	00000097          	auipc	ra,0x0
 4f6:	f56080e7          	jalr	-170(ra) # 448 <putc>
  while(--i >= 0)
 4fa:	197d                	addi	s2,s2,-1
 4fc:	ff3918e3          	bne	s2,s3,4ec <printint+0x82>
}
 500:	70e2                	ld	ra,56(sp)
 502:	7442                	ld	s0,48(sp)
 504:	74a2                	ld	s1,40(sp)
 506:	7902                	ld	s2,32(sp)
 508:	69e2                	ld	s3,24(sp)
 50a:	6121                	addi	sp,sp,64
 50c:	8082                	ret
    x = -xx;
 50e:	40b005bb          	negw	a1,a1
    neg = 1;
 512:	4885                	li	a7,1
    x = -xx;
 514:	bf85                	j	484 <printint+0x1a>

0000000000000516 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 516:	7119                	addi	sp,sp,-128
 518:	fc86                	sd	ra,120(sp)
 51a:	f8a2                	sd	s0,112(sp)
 51c:	f4a6                	sd	s1,104(sp)
 51e:	f0ca                	sd	s2,96(sp)
 520:	ecce                	sd	s3,88(sp)
 522:	e8d2                	sd	s4,80(sp)
 524:	e4d6                	sd	s5,72(sp)
 526:	e0da                	sd	s6,64(sp)
 528:	fc5e                	sd	s7,56(sp)
 52a:	f862                	sd	s8,48(sp)
 52c:	f466                	sd	s9,40(sp)
 52e:	f06a                	sd	s10,32(sp)
 530:	ec6e                	sd	s11,24(sp)
 532:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 534:	0005c903          	lbu	s2,0(a1)
 538:	18090f63          	beqz	s2,6d6 <vprintf+0x1c0>
 53c:	8aaa                	mv	s5,a0
 53e:	8b32                	mv	s6,a2
 540:	00158493          	addi	s1,a1,1
  state = 0;
 544:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 546:	02500a13          	li	s4,37
 54a:	4c55                	li	s8,21
 54c:	00000c97          	auipc	s9,0x0
 550:	3bcc8c93          	addi	s9,s9,956 # 908 <malloc+0x12e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 554:	02800d93          	li	s11,40
  putc(fd, 'x');
 558:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 55a:	00000b97          	auipc	s7,0x0
 55e:	406b8b93          	addi	s7,s7,1030 # 960 <digits>
 562:	a839                	j	580 <vprintf+0x6a>
        putc(fd, c);
 564:	85ca                	mv	a1,s2
 566:	8556                	mv	a0,s5
 568:	00000097          	auipc	ra,0x0
 56c:	ee0080e7          	jalr	-288(ra) # 448 <putc>
 570:	a019                	j	576 <vprintf+0x60>
    } else if(state == '%'){
 572:	01498d63          	beq	s3,s4,58c <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 576:	0485                	addi	s1,s1,1
 578:	fff4c903          	lbu	s2,-1(s1)
 57c:	14090d63          	beqz	s2,6d6 <vprintf+0x1c0>
    if(state == 0){
 580:	fe0999e3          	bnez	s3,572 <vprintf+0x5c>
      if(c == '%'){
 584:	ff4910e3          	bne	s2,s4,564 <vprintf+0x4e>
        state = '%';
 588:	89d2                	mv	s3,s4
 58a:	b7f5                	j	576 <vprintf+0x60>
      if(c == 'd'){
 58c:	11490c63          	beq	s2,s4,6a4 <vprintf+0x18e>
 590:	f9d9079b          	addiw	a5,s2,-99
 594:	0ff7f793          	zext.b	a5,a5
 598:	10fc6e63          	bltu	s8,a5,6b4 <vprintf+0x19e>
 59c:	f9d9079b          	addiw	a5,s2,-99
 5a0:	0ff7f713          	zext.b	a4,a5
 5a4:	10ec6863          	bltu	s8,a4,6b4 <vprintf+0x19e>
 5a8:	00271793          	slli	a5,a4,0x2
 5ac:	97e6                	add	a5,a5,s9
 5ae:	439c                	lw	a5,0(a5)
 5b0:	97e6                	add	a5,a5,s9
 5b2:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 5b4:	008b0913          	addi	s2,s6,8
 5b8:	4685                	li	a3,1
 5ba:	4629                	li	a2,10
 5bc:	000b2583          	lw	a1,0(s6)
 5c0:	8556                	mv	a0,s5
 5c2:	00000097          	auipc	ra,0x0
 5c6:	ea8080e7          	jalr	-344(ra) # 46a <printint>
 5ca:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 5cc:	4981                	li	s3,0
 5ce:	b765                	j	576 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 5d0:	008b0913          	addi	s2,s6,8
 5d4:	4681                	li	a3,0
 5d6:	4629                	li	a2,10
 5d8:	000b2583          	lw	a1,0(s6)
 5dc:	8556                	mv	a0,s5
 5de:	00000097          	auipc	ra,0x0
 5e2:	e8c080e7          	jalr	-372(ra) # 46a <printint>
 5e6:	8b4a                	mv	s6,s2
      state = 0;
 5e8:	4981                	li	s3,0
 5ea:	b771                	j	576 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5ec:	008b0913          	addi	s2,s6,8
 5f0:	4681                	li	a3,0
 5f2:	866a                	mv	a2,s10
 5f4:	000b2583          	lw	a1,0(s6)
 5f8:	8556                	mv	a0,s5
 5fa:	00000097          	auipc	ra,0x0
 5fe:	e70080e7          	jalr	-400(ra) # 46a <printint>
 602:	8b4a                	mv	s6,s2
      state = 0;
 604:	4981                	li	s3,0
 606:	bf85                	j	576 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 608:	008b0793          	addi	a5,s6,8
 60c:	f8f43423          	sd	a5,-120(s0)
 610:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 614:	03000593          	li	a1,48
 618:	8556                	mv	a0,s5
 61a:	00000097          	auipc	ra,0x0
 61e:	e2e080e7          	jalr	-466(ra) # 448 <putc>
  putc(fd, 'x');
 622:	07800593          	li	a1,120
 626:	8556                	mv	a0,s5
 628:	00000097          	auipc	ra,0x0
 62c:	e20080e7          	jalr	-480(ra) # 448 <putc>
 630:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 632:	03c9d793          	srli	a5,s3,0x3c
 636:	97de                	add	a5,a5,s7
 638:	0007c583          	lbu	a1,0(a5)
 63c:	8556                	mv	a0,s5
 63e:	00000097          	auipc	ra,0x0
 642:	e0a080e7          	jalr	-502(ra) # 448 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 646:	0992                	slli	s3,s3,0x4
 648:	397d                	addiw	s2,s2,-1
 64a:	fe0914e3          	bnez	s2,632 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 64e:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 652:	4981                	li	s3,0
 654:	b70d                	j	576 <vprintf+0x60>
        s = va_arg(ap, char*);
 656:	008b0913          	addi	s2,s6,8
 65a:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 65e:	02098163          	beqz	s3,680 <vprintf+0x16a>
        while(*s != 0){
 662:	0009c583          	lbu	a1,0(s3)
 666:	c5ad                	beqz	a1,6d0 <vprintf+0x1ba>
          putc(fd, *s);
 668:	8556                	mv	a0,s5
 66a:	00000097          	auipc	ra,0x0
 66e:	dde080e7          	jalr	-546(ra) # 448 <putc>
          s++;
 672:	0985                	addi	s3,s3,1
        while(*s != 0){
 674:	0009c583          	lbu	a1,0(s3)
 678:	f9e5                	bnez	a1,668 <vprintf+0x152>
        s = va_arg(ap, char*);
 67a:	8b4a                	mv	s6,s2
      state = 0;
 67c:	4981                	li	s3,0
 67e:	bde5                	j	576 <vprintf+0x60>
          s = "(null)";
 680:	00000997          	auipc	s3,0x0
 684:	28098993          	addi	s3,s3,640 # 900 <malloc+0x126>
        while(*s != 0){
 688:	85ee                	mv	a1,s11
 68a:	bff9                	j	668 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 68c:	008b0913          	addi	s2,s6,8
 690:	000b4583          	lbu	a1,0(s6)
 694:	8556                	mv	a0,s5
 696:	00000097          	auipc	ra,0x0
 69a:	db2080e7          	jalr	-590(ra) # 448 <putc>
 69e:	8b4a                	mv	s6,s2
      state = 0;
 6a0:	4981                	li	s3,0
 6a2:	bdd1                	j	576 <vprintf+0x60>
        putc(fd, c);
 6a4:	85d2                	mv	a1,s4
 6a6:	8556                	mv	a0,s5
 6a8:	00000097          	auipc	ra,0x0
 6ac:	da0080e7          	jalr	-608(ra) # 448 <putc>
      state = 0;
 6b0:	4981                	li	s3,0
 6b2:	b5d1                	j	576 <vprintf+0x60>
        putc(fd, '%');
 6b4:	85d2                	mv	a1,s4
 6b6:	8556                	mv	a0,s5
 6b8:	00000097          	auipc	ra,0x0
 6bc:	d90080e7          	jalr	-624(ra) # 448 <putc>
        putc(fd, c);
 6c0:	85ca                	mv	a1,s2
 6c2:	8556                	mv	a0,s5
 6c4:	00000097          	auipc	ra,0x0
 6c8:	d84080e7          	jalr	-636(ra) # 448 <putc>
      state = 0;
 6cc:	4981                	li	s3,0
 6ce:	b565                	j	576 <vprintf+0x60>
        s = va_arg(ap, char*);
 6d0:	8b4a                	mv	s6,s2
      state = 0;
 6d2:	4981                	li	s3,0
 6d4:	b54d                	j	576 <vprintf+0x60>
    }
  }
}
 6d6:	70e6                	ld	ra,120(sp)
 6d8:	7446                	ld	s0,112(sp)
 6da:	74a6                	ld	s1,104(sp)
 6dc:	7906                	ld	s2,96(sp)
 6de:	69e6                	ld	s3,88(sp)
 6e0:	6a46                	ld	s4,80(sp)
 6e2:	6aa6                	ld	s5,72(sp)
 6e4:	6b06                	ld	s6,64(sp)
 6e6:	7be2                	ld	s7,56(sp)
 6e8:	7c42                	ld	s8,48(sp)
 6ea:	7ca2                	ld	s9,40(sp)
 6ec:	7d02                	ld	s10,32(sp)
 6ee:	6de2                	ld	s11,24(sp)
 6f0:	6109                	addi	sp,sp,128
 6f2:	8082                	ret

00000000000006f4 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 6f4:	715d                	addi	sp,sp,-80
 6f6:	ec06                	sd	ra,24(sp)
 6f8:	e822                	sd	s0,16(sp)
 6fa:	1000                	addi	s0,sp,32
 6fc:	e010                	sd	a2,0(s0)
 6fe:	e414                	sd	a3,8(s0)
 700:	e818                	sd	a4,16(s0)
 702:	ec1c                	sd	a5,24(s0)
 704:	03043023          	sd	a6,32(s0)
 708:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 70c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 710:	8622                	mv	a2,s0
 712:	00000097          	auipc	ra,0x0
 716:	e04080e7          	jalr	-508(ra) # 516 <vprintf>
}
 71a:	60e2                	ld	ra,24(sp)
 71c:	6442                	ld	s0,16(sp)
 71e:	6161                	addi	sp,sp,80
 720:	8082                	ret

0000000000000722 <printf>:

void
printf(const char *fmt, ...)
{
 722:	711d                	addi	sp,sp,-96
 724:	ec06                	sd	ra,24(sp)
 726:	e822                	sd	s0,16(sp)
 728:	1000                	addi	s0,sp,32
 72a:	e40c                	sd	a1,8(s0)
 72c:	e810                	sd	a2,16(s0)
 72e:	ec14                	sd	a3,24(s0)
 730:	f018                	sd	a4,32(s0)
 732:	f41c                	sd	a5,40(s0)
 734:	03043823          	sd	a6,48(s0)
 738:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 73c:	00840613          	addi	a2,s0,8
 740:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 744:	85aa                	mv	a1,a0
 746:	4505                	li	a0,1
 748:	00000097          	auipc	ra,0x0
 74c:	dce080e7          	jalr	-562(ra) # 516 <vprintf>
}
 750:	60e2                	ld	ra,24(sp)
 752:	6442                	ld	s0,16(sp)
 754:	6125                	addi	sp,sp,96
 756:	8082                	ret

0000000000000758 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 758:	1141                	addi	sp,sp,-16
 75a:	e422                	sd	s0,8(sp)
 75c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 75e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 762:	00001797          	auipc	a5,0x1
 766:	89e7b783          	ld	a5,-1890(a5) # 1000 <freep>
 76a:	a02d                	j	794 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 76c:	4618                	lw	a4,8(a2)
 76e:	9f2d                	addw	a4,a4,a1
 770:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 774:	6398                	ld	a4,0(a5)
 776:	6310                	ld	a2,0(a4)
 778:	a83d                	j	7b6 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 77a:	ff852703          	lw	a4,-8(a0)
 77e:	9f31                	addw	a4,a4,a2
 780:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 782:	ff053683          	ld	a3,-16(a0)
 786:	a091                	j	7ca <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 788:	6398                	ld	a4,0(a5)
 78a:	00e7e463          	bltu	a5,a4,792 <free+0x3a>
 78e:	00e6ea63          	bltu	a3,a4,7a2 <free+0x4a>
{
 792:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 794:	fed7fae3          	bgeu	a5,a3,788 <free+0x30>
 798:	6398                	ld	a4,0(a5)
 79a:	00e6e463          	bltu	a3,a4,7a2 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 79e:	fee7eae3          	bltu	a5,a4,792 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 7a2:	ff852583          	lw	a1,-8(a0)
 7a6:	6390                	ld	a2,0(a5)
 7a8:	02059813          	slli	a6,a1,0x20
 7ac:	01c85713          	srli	a4,a6,0x1c
 7b0:	9736                	add	a4,a4,a3
 7b2:	fae60de3          	beq	a2,a4,76c <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 7b6:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7ba:	4790                	lw	a2,8(a5)
 7bc:	02061593          	slli	a1,a2,0x20
 7c0:	01c5d713          	srli	a4,a1,0x1c
 7c4:	973e                	add	a4,a4,a5
 7c6:	fae68ae3          	beq	a3,a4,77a <free+0x22>
    p->s.ptr = bp->s.ptr;
 7ca:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 7cc:	00001717          	auipc	a4,0x1
 7d0:	82f73a23          	sd	a5,-1996(a4) # 1000 <freep>
}
 7d4:	6422                	ld	s0,8(sp)
 7d6:	0141                	addi	sp,sp,16
 7d8:	8082                	ret

00000000000007da <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 7da:	7139                	addi	sp,sp,-64
 7dc:	fc06                	sd	ra,56(sp)
 7de:	f822                	sd	s0,48(sp)
 7e0:	f426                	sd	s1,40(sp)
 7e2:	f04a                	sd	s2,32(sp)
 7e4:	ec4e                	sd	s3,24(sp)
 7e6:	e852                	sd	s4,16(sp)
 7e8:	e456                	sd	s5,8(sp)
 7ea:	e05a                	sd	s6,0(sp)
 7ec:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 7ee:	02051493          	slli	s1,a0,0x20
 7f2:	9081                	srli	s1,s1,0x20
 7f4:	04bd                	addi	s1,s1,15
 7f6:	8091                	srli	s1,s1,0x4
 7f8:	0014899b          	addiw	s3,s1,1
 7fc:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7fe:	00001517          	auipc	a0,0x1
 802:	80253503          	ld	a0,-2046(a0) # 1000 <freep>
 806:	c515                	beqz	a0,832 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 808:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 80a:	4798                	lw	a4,8(a5)
 80c:	02977f63          	bgeu	a4,s1,84a <malloc+0x70>
 810:	8a4e                	mv	s4,s3
 812:	0009871b          	sext.w	a4,s3
 816:	6685                	lui	a3,0x1
 818:	00d77363          	bgeu	a4,a3,81e <malloc+0x44>
 81c:	6a05                	lui	s4,0x1
 81e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 822:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 826:	00000917          	auipc	s2,0x0
 82a:	7da90913          	addi	s2,s2,2010 # 1000 <freep>
  if(p == (char*)-1)
 82e:	5afd                	li	s5,-1
 830:	a895                	j	8a4 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 832:	00000797          	auipc	a5,0x0
 836:	7de78793          	addi	a5,a5,2014 # 1010 <base>
 83a:	00000717          	auipc	a4,0x0
 83e:	7cf73323          	sd	a5,1990(a4) # 1000 <freep>
 842:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 844:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 848:	b7e1                	j	810 <malloc+0x36>
      if(p->s.size == nunits)
 84a:	02e48c63          	beq	s1,a4,882 <malloc+0xa8>
        p->s.size -= nunits;
 84e:	4137073b          	subw	a4,a4,s3
 852:	c798                	sw	a4,8(a5)
        p += p->s.size;
 854:	02071693          	slli	a3,a4,0x20
 858:	01c6d713          	srli	a4,a3,0x1c
 85c:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 85e:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 862:	00000717          	auipc	a4,0x0
 866:	78a73f23          	sd	a0,1950(a4) # 1000 <freep>
      return (void*)(p + 1);
 86a:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 86e:	70e2                	ld	ra,56(sp)
 870:	7442                	ld	s0,48(sp)
 872:	74a2                	ld	s1,40(sp)
 874:	7902                	ld	s2,32(sp)
 876:	69e2                	ld	s3,24(sp)
 878:	6a42                	ld	s4,16(sp)
 87a:	6aa2                	ld	s5,8(sp)
 87c:	6b02                	ld	s6,0(sp)
 87e:	6121                	addi	sp,sp,64
 880:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 882:	6398                	ld	a4,0(a5)
 884:	e118                	sd	a4,0(a0)
 886:	bff1                	j	862 <malloc+0x88>
  hp->s.size = nu;
 888:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 88c:	0541                	addi	a0,a0,16
 88e:	00000097          	auipc	ra,0x0
 892:	eca080e7          	jalr	-310(ra) # 758 <free>
  return freep;
 896:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 89a:	d971                	beqz	a0,86e <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 89c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 89e:	4798                	lw	a4,8(a5)
 8a0:	fa9775e3          	bgeu	a4,s1,84a <malloc+0x70>
    if(p == freep)
 8a4:	00093703          	ld	a4,0(s2)
 8a8:	853e                	mv	a0,a5
 8aa:	fef719e3          	bne	a4,a5,89c <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 8ae:	8552                	mv	a0,s4
 8b0:	00000097          	auipc	ra,0x0
 8b4:	b68080e7          	jalr	-1176(ra) # 418 <sbrk>
  if(p == (char*)-1)
 8b8:	fd5518e3          	bne	a0,s5,888 <malloc+0xae>
        return 0;
 8bc:	4501                	li	a0,0
 8be:	bf45                	j	86e <malloc+0x94>
