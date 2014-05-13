// rc4.pde: small Processing program to animate the pseudo-random
// generator portion of the RC4 algorithm
// 
// Copyright (c) 2014 John Graham-Cumming

// The number of elements in the key schedule. Normally this is 256
// but for better presentation limit it to something smaller

int count = 32;

// The key schedule and the i/j positions in s[]

int s[] = new int[count];
int i = 0;
int j = 0;

// Width and height of the canvas on which the drawing is made. Although
// this can be changed the program makes assumptions about the size.

int w = 1280;
int h = 300;

// Distance from the left-hand and right-hand edges to reserve to form a
// margin around the boxes containing the key schedule.

int margin = 48;

// The size of the boxes. Each box contains a single number from s[]

int box = (w - margin*2)/count;

// Used to store the sequence of values output by the algorithm. Only stores
// the last count items and is used to make the scrolling display at the bottom
// of the canvas.
//
// pos points to the location where the next item should be written. d is the
// number of items written into the array (maxes out at count). Between the 
// two a circular buffer is implemented.

int o[] = new int[count];
int pos = 0;
int d = 0;

// Useful to have these as constants rather than have color(x,y,z) 
// throughout the code.

color black = color(0, 0, 0);
color red = color(255, 0, 0);
color white = color(255, 255, 255);

// Used to track the internal state of the algorithm as it runs through
// the four steps. See the function std() for the states.

int state = 0;

void setup() {
  size(w, h);

  // Fake up the key schedule by randomly permuting the values in 
  // s[]  
  
  for (int i = 0; i < count; i++) {
    s[i] = i;
  }
  for (int i = 0; i < count; i++) {
    int x = (int)random(count - i);
    int t = s[i];
    s[i] = s[x];
    s[x] = t;
  }      
}

void draw() {
  clear();

  textAlign(CENTER, CENTER);
  fill(white);
  textSize(16);
  text("s[]", margin - 10, h/2 + box/2);

  // Draw the boxes and the put the appropriate number from s[]
  // inside each box

  int x = margin;
  int y = h/2;
  for (int i = 0; i < count; i++) {
    fill(white);
    stroke(0);
    rect(x, y, box, box);
    si(i, black);
    textAlign(CENTER, CENTER);
    textSize(8);
    fill(white);
    text(nf(i, 1), x + box/2, y + box + 4);
    x = x + box;
  }

  // If the algorithm has output any values draw them in red at the
  // bottom of the canvas
  
  if (d > 0) {
    x = width - margin - d * box;
    int p = (d<count)?0:pos;

    for (int i = 0; i < d; i++) {
      fill(red);
      textAlign(CENTER, CENTER);
      textSize(16);
      text(nf(o[p], 1), x + box/2, h - 40);    
      p = p + 1;
      if (p == count) {
          p = 0;
      }
      x = x + box;
    }
  }
  
  drawi(white); 
  drawj(white); 
  std();
    
  doState();
  
  delay(100);
  
  state = state + 1;
  if (state == 4) {
    state = 0;
  }
}

// si: draw the number in s[i] in the appropriate box in the color c
void si(int i, color c) {
  int x = margin + i * box;
  int y = h/2;
  
  fill(c);
  textAlign(CENTER, CENTER);
  textSize(16);
  text(nf(s[i], 1), x + box/2, y + box/2);
}

// drawij: used to put i or j in the right place on screen using the
// color c. Pass in the name "i" or "j" in s and the value of the
// corresponding i or j variable in x.
void drawij(String s, int ij, color c) {
  int x = margin + box * ij;
  int y = h/2;
  fill(c);
  textAlign(CENTER, CENTER);
  textSize(16);
  stroke(0);
  text(s, x + box/4, y - 14);
}

// drawi: draw the i pointer in the appropriate position in color c
void drawi(color c) {
  drawij("i", i, c);
}
// drawj: draw the j pointer in the appropriate position in color c
void drawj(color c) {
  drawij("j", j, c);
}

// doState: perform whatever action is needed for the current state
// The RC4 algorithm is:
//
// i := 0
// j := 0
// while GeneratingOutput:
//    i := (i + 1) mod 256            (state 0)
//    j := (j + S[i]) mod 256         (state 1)
//    swap values of S[i] and S[j]    (state 2)
//    K := S[(S[i] + S[j]) mod 256]   (state 3)
//    output K
// endwhile
void doState() {
  switch (state) {
      case 0: // i := (i + 1) mod 256
      drawi(red); 
      int oldi = i;
      i = i + 1;
      if (i == count) {
          i = 0;
      }
      arrow(oldi, i);
      break;
      
      case 1: // j := (j + S[i]) mod 256
      drawj(red); 
      int oldj = j;
      j = j + s[i];
      if (j >= count) {
          j -= count;
      }
      si(i, red);
      arrow(oldj, j);
      break;
      
      case 2: // swap values of S[i] and S[j]
      case 3: // K := S[(S[i] + S[j]) mod 256]
      si(i, red);
      si(j, red);
      stroke(red);
      noFill();
      
      // This draws the curve that links i and j
      
      beginShape();
      int left = margin + box/2;
      int top = h/2 + box + 30;
      curveVertex(left + i*box-40, top-100);
      curveVertex(left + i*box, top);
      curveVertex(left + j*box, top);
      curveVertex(left + j*box+40, top-100);
      endShape();
      
      // If in state 2 do the swap, otherwise do the add
      
      if (state == 2) { 
        int t = s[i];
        s[i] = s[j];
        s[j] = t;
      } else {
         int k = s[i] + s[j];
         if (k >= count) {
           k = k - count;
         }
        si(k, red);
        noFill();
        ellipse(left + k*box, h/2+box/2, box*2, box*2);
        fill(red);
        textAlign(CENTER, CENTER);
        textSize(16);
        text(String.format("%d + %d mod %d = %d, s[%d] = %d",
          s[i], s[j], count, k, k, s[k]), left+i*box+(j-i)*box/2, top+20);
        o[pos] = s[k];
        pos = pos + 1;
        if (d < count) {
          d = d + 1;
        }
        if (pos == count) {
          pos = 0;
        }
      }
      break;      
  }
}

// Draw an arrow starting at box s and ending at box e
void arrow(int s, int e) {
  fill(red);
  stroke(red);
  line(margin + box/2 + s * box, h/2 - 30, margin+box/2 + e * box, h/2 - 30);
  if (e > s) {
    line(margin + box/2 + e * box, h/2 - 30, margin + box/2 + e * box - 10, h/2 - 40);
    line(margin + box/2 + e * box, h/2 - 30, margin + box/2 + e * box - 10, h/2 - 20);
  } else {
    line(margin + box/2 + e * box, h/2 - 30, margin + box/2 + e * box + 10, h/2 - 40);
    line(margin + box/2 + e * box, h/2 - 30, margin + box/2 + e * box + 10, h/2 - 20);
  }
}

// stp: writes a state string from std() at the appropriate position
// (they are in a column at the top left of the screen)
void stp(int i, String s) {
  text(s, 10, 10 + i * 20);
}

// std: draw the four states on screen and highlight the current
// state in red
void std() {
  textAlign(LEFT, CENTER);

  for (int i = 0; i < 4; i++) {
    if (i == state) {
      fill(red);
    } else {
      fill(white);
    }
  
    switch (i) {
    case 0:  
        stp(i, "Add one to i");
        break;
    case 1:
        stp(i, "Add s[i] to j");
        break;
    case 2:
        stp(i, "Swap s[i] and s[j]");
        break;
    case 3:
        stp(i, "Add s[i] and s[j] and output value in s[s[i] + s[j]]");
        break;
    }
  }
}

