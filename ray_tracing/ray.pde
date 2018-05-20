final float EPSILON = 0.001; // 微小距離

class Ray {
  Vec origin; // 始点
  Vec dir;    // 方向（単位ベクトル）

  Ray(Vec origin, Vec dir) {
    this.dir = dir.normalize();
    this.origin = origin.add(this.dir.scale(EPSILON));
  }
}
