
#include <stdint.h>
#include <stdbool.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>
#include <dirent.h>

const char *SEARCH_DATA = "LevelSummary";
const char *REPLACE_WITH = "SpecialEvent";
const size_t SEARCH_DATA_LEN = 13;

int downgradeMap(const char *fname) {
	FILE *fd = fopen(fname, "r");
	if (fd != NULL) {
		bool founddata = false;
		uint8_t *data, *ptr;
		size_t len, i = 0;
		fseek(fd, 0, 2);
		len = ftell(fd);
		fseek(fd, 0, 0);
		data = malloc(len);
		fread(data, len, 1, fd);
		fclose(fd);
		while (ptr = memchr(&data[i], SEARCH_DATA[0], len - i)) {
			bool success = true;
			// printf("%X\n", (unsigned int)ptr);
			i = ptr - data;
			for (size_t j=1; j<SEARCH_DATA_LEN; j++) {
				if (data[i+j] != SEARCH_DATA[j]) {
					success = false;
					break;
				}
			}
			if (success) {
				founddata = true;
				break;
			}
			i++;
		}
		if (founddata) {
			memcpy(ptr, REPLACE_WITH, SEARCH_DATA_LEN);
			fd = fopen(fname, "w");
			if (fd != NULL) {
				fwrite(data, len, 1, fd);
				fclose(fd);
			} else {
				printf("Warning: Failed to write file \"%s\"\n", fname);
				return -2;
			}
		} else {
			printf("Warning: Couldn't find search data \"%s\" in file \"%s\", skipping.\n", SEARCH_DATA, fname);
		}
		free(data);
	} else {
		printf("Warning: Failed to read file \"%s\"\n", fname);
		return -1;
	}
	return 0;
}

int downgradeMapsInDir(const char *dname, const char *ename) {
	DIR *dp;
	struct dirent *ep;
	struct stat sb;
	char *fname;
	dp = opendir(dname);
	if (dp == NULL) {
		printf("Failed to open directory: \"%s\"\n", dname);
		return -1;
	}
	while (ep = readdir(dp)) {
		if (strcmp(ep->d_name, "..") && strcmp(ep->d_name, ".")) {
			if (!strcmp(ename, &ep->d_name[strlen(ep->d_name)-strlen(ename)])) {
				printf("Downgrading map: \"%s\"\n", ep->d_name);
				fname = malloc(strlen(ep->d_name) + strlen(dname) + 2);
				memcpy(fname, dname, strlen(dname));
				fname[strlen(dname)] = '/';
				memcpy(&fname[strlen(dname)+1], ep->d_name, strlen(ep->d_name)+1);
				if (stat(fname, &sb) == 0) {
					int rv;
					if (S_ISREG(sb.st_mode)) {
						if ((rv = downgradeMap(fname)) != 0) {
							return rv;
						}
					} else if (S_ISDIR(sb.st_mode)) {
						if ((rv = downgradeMapsInDir(fname, ename)) != 0) {
							return rv;
						}
					}
				}
				free(fname);
			}
		}
	}
	closedir(dp);
	return 0;
}

int main(int argc, char **argv) {
	char *ename = ".unr";
	int rv;
	if (argc < 2) {
		printf("Usage: %s [-d directory] [-e .ext] files\nNote: file extension defaults to \".unr\"\n", argv[0]);
		return 0;
	}
	for (int i=1; i<argc; i++) {
		if (!strcmp(argv[i], "-e")) {
			i++;
			ename = argv[i];
		}
	}
	for (int i=1; i<argc; i++) {
		if (strcmp(argv[i], "-d")) {
			// downgrade if path is not a directory
			if ((rv = downgradeMap(argv[i])) != 0) {
				return rv;
			}
		} else {
			// downgrade all in the directory if path is a directory
			i++;
			if (i >= argc) {
				printf("-d argument must be followed by a directory path.\n");
				return 0;
			}
			if ((rv = downgradeMapsInDir(argv[i], ename)) != 0) {
				return rv;
			}
		}
	}
	return 0;
}
