#include <stdlib.h>
#include <stdio.h>
#include <string.h>

typedef struct {
  int r;
  int g;
  int b;
} Color;

typedef struct {
  int height;
  int width;
  Color **data;
  int loaded;
} Image;

Image readP3(const char* filename) {
  FILE *fp = fopen(filename, "r");
  if (fp == NULL) {
    Image i;
    i.loaded = 0;
    return i;
  }
  char type[256];
  int height, width, max;

  fscanf(fp, "%s %d %d %d", type, &width, &height, &max);

  Image image;
  image.height = height;
  image.width = width;
  image.loaded = 1;

  image.data = malloc(image.height * sizeof(Color*));
  for (int i = 0; i < image.height; i++) {
    image.data[i] = malloc(image.width * sizeof(Color));
  }

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      Color c;
      fscanf(fp, "%d %d %d", &c.r, &c.g, &c.b);
      image.data[y][x] = c;
    }
  }

  fclose(fp);
  return image;
}

void deleteImage(Image image) {
  if (!image.loaded) {
    return;
  }
  for (int i = 0; i < image.height; i++) {
    free(image.data[i]);
  }
  free(image.data);
}

// If Proportion threshold % of pixels have changed in sum of rgb by pixel threshold
#define PROPORTION_THRESHOLD 0.05
#define PIXEL_THRESHOLD 50
int detectMotion(Image a, Image b) {
  int amountChanged = 0;
  if (a.width != b.width && a.height != b.height) {
    return 1;
  }
  for (int y = 0; y < a.height; y++) {
    for (int x = 0; x < a.width; x++) {
      Color ac = a.data[y][x];
      Color bc = b.data[y][x];
      if (abs((ac.r + ac.g + ac.b) - (bc.r + bc.g + bc.b)) > PIXEL_THRESHOLD) {
        amountChanged++;
      }
    }
  }
  return amountChanged > (a.width * a.height * PROPORTION_THRESHOLD);
}

int main(int argc, char* argv[]) {
  if (argc < 3) {
    printf("Usage: ./detect file1 file2\n");
  }
  Image a = readP3(argv[1]);
  Image b = readP3(argv[2]);
  int motionDetected = 1;
  if (a.loaded && b.loaded) {
    motionDetected = detectMotion(a, b);
  }
  deleteImage(a);
  deleteImage(b);
  return !motionDetected;
}
