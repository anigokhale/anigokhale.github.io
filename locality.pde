import java.util.*;
import java.lang.*;
import java.io.*;

ArrayList<Node> nodes = new ArrayList<Node>();

int numNodes = 750;
int numConnections = 15;
float dt = 0.001;
float t = 0;
float newConnectionChance = 0.1;
float removeConnectionChance = 0.1;
float outsideInfluence = 0.1;
int flashLength = 5;
float connectionDistFactor = 10;
float moveSpeed = 1;
float nodeRadius = 10;
boolean run = true;

void setup() {
  fullScreen();

  while (nodes.size() < numNodes) {
    float radius = 10;
    float x = random(radius, width-radius), y = random(radius, height-radius);

    Node n = new Node(x, y);
    while (n.touching()) {
      radius = 10;
      x = random(radius, width-radius);
      y = random(radius, height-radius);
      n = new Node(x, y);
    }
    nodes.add(n);
  }
  for (Node n : nodes) {
    ArrayList<Node> options = new ArrayList<Node>(nodes);
    options.remove(n);
    for (Node existingConnection : n.connections) {
      options.remove(existingConnection);
    }
    ArrayList<Node> toRemove = new ArrayList<Node>();
    for (Node r : options) {
      if (r.connections.size() >= numConnections) toRemove.add(r);
    }
    for (Node r : toRemove) options.remove(r);
    try {
      Collections.sort(options, new CompareNode(n));
    }
    catch (IllegalArgumentException e) {
      e.printStackTrace();
    }
    for (int i = 0; i < (int) random(2, numConnections - n.connections.size()); i++) {
      try {
        n.addConnection(options.get(i));
        options.get(i).addConnection(n);
      }
      catch (IndexOutOfBoundsException e) {
      }
    }
  }
}

void draw() {
  background(200);
  for (Node n : nodes) {
    if (run) n.update();
    n.display();
  }
  if (run) t += dt;
}

class Node {
  float radius = nodeRadius;
  PVector pos;
  float freq;
  float val;
  color col;
  ArrayList<Node> connections = new ArrayList<Node>();

  Node(float x, float y) {
    pos = new PVector(x, y);
    freq = random(-500, 600);
    col = color(100);
    val = 0;
  }

  void addConnections(ArrayList<Node> ns) {
    for (Node n : ns) {
      addConnection(n);
    }
  }

  void addConnection(Node n) {
    connections.add(n);
  }

  boolean touching() {
    for (Node n : nodes) {
      if (n != this && this.pos.dist(n.pos) <= this.radius + n.radius) return true;
    }
    return false;
  }

  void update() {
    PVector change = new PVector(0, 0);
    float otherFreq = 0;
    for (Node n : connections) {
      change.add(n.pos.copy().sub(this.pos).mult(this.numCommonConnections(n)).mult(dt).mult(moveSpeed));
      otherFreq += n.freq;
    }
    otherFreq /= (float)connections.size();
    if (connections.size() > 0) freq = (otherFreq * outsideInfluence + (1.0 - outsideInfluence) * freq);
    this.pos.add(change);

    if (Math.random() < removeConnectionChance && connections.size() > numConnections) {
      try {
        Collections.sort(this.connections, new CompareNode(this));
        Node remove = this.connections.get((int)(Math.random() * connections.size()));
        this.connections.remove(remove);
        remove.connections.remove(this);
      }
      catch(Exception e) {
      }
    }

    if (Math.random() < newConnectionChance) {
      ArrayList<Node> options = new ArrayList<Node>(nodes);
      options.remove(this);
      for (Node existingConnection : this.connections) {
        options.remove(existingConnection);
      }
      ArrayList<Node> toRemove = new ArrayList<Node>();
      for (Node r : options) {
        if (r.connections.size() >= numConnections) toRemove.add(r);
      }
      for (Node r : toRemove) options.remove(r);
      try {
        Collections.sort(options, new CompareNode(this));
      }
      catch (IllegalArgumentException e) {
        //e.printStackTrace();
      }
      if (options.size() > 0) {
        Node selected = options.get(0);
        if (selected.pos.dist(this.pos) < radius * connectionDistFactor && this.connections.size() < numConnections * 2 && selected.connections.size() < numConnections * 2) {
          this.addConnection(selected);
          selected.addConnection(this);
        }
      }
    }
    val = sin(t * freq);
    col = color(map(val, 0, 1, 0, 255));
  }

  int numCommonConnections(Node n) {
    int total = 0;

    for (Node neighbor : n.connections) {
      if (neighbor != this && this.connections.indexOf(neighbor) != -1 && this.pos.dist(neighbor.pos) > radius*5) total++;
    }

    return total;
  }

  void display() {
    noStroke();
    fill(col);
    ellipse(pos.x, pos.y, radius*2, radius*2);

    strokeWeight(1);
    for (Node n : connections) {
      stroke(lerpColor(this.col, n.col, 0.5));
      strokeWeight(.1);
      line(pos.x, pos.y, n.pos.x, n.pos.y);
    }
  }
}
class CompareNode implements Comparator<Node> {
  Node n;
  CompareNode(Node n) {
    this.n = n;
  }
  int compare(Node a, Node b) {
    return (int)(n.pos.dist(a.pos) - n.pos.dist(b.pos));
  }
}
