CC = gzip
CFLAGS = -k

OBJS = s1.log.gz s2.log.gz s3.log.gz

all:
	$(CC) $(CFLAGS) s1.log
	$(CC) $(CFLAGS) s2.log
	$(CC) $(CFLAGS) s3.log
	$(CC) $(CFLAGS) stock-2.log
	$(CC) $(CFLAGS) stock-6.log


clean:
	rm s1.log.gz s2.log.gz s3.log.gz stock-2.log.gz stock-6.log.gz