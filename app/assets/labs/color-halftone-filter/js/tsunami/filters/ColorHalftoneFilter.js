tsunami = this.tsunami || {};
tsunami.filters = tsunami.filters || {};

(function() {

  tsunami.filters.ColorHalftoneFilter = function(pixelsPerPoint) {
    this.initialize(pixelsPerPoint);
  }

  var p = tsunami.filters.ColorHalftoneFilter.prototype;

  p.initialize = function(pixelsPerPoint) {
    this.pixelsPerPoint = pixelsPerPoint;
    this.colors = [
      // new tsunami.filters.ColorHalftoneFilterColor("k", "#000000",  45, 1),
      new tsunami.filters.ColorHalftoneFilterColor("y", "#FFFF00",  96, 1),
      new tsunami.filters.ColorHalftoneFilterColor("m", "#FF00FF", 162, 1),
      new tsunami.filters.ColorHalftoneFilterColor("c", "#00FFFF", 108, 1)
    ];
  }

  p.applyFilter = function(ctx) {
    var width = ctx.canvas.width;
    var height = ctx.canvas.height;

    var imageData = ctx.getImageData(0, 0, width, height);

    ctx.fillStyle = "#fff";
    ctx.fillRect(0, 0, width, height);

    var buffr = 10;
    var hypotenuse = Math.sqrt(width * width + height * height);
    hypotenuse = Math.ceil(hypotenuse / this.pixelsPerPoint) * this.pixelsPerPoint + 2 * buffr;

    var canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    var context = canvas.getContext('2d');


    for (var cIndex = 0; cIndex < this.colors.length; cIndex++) {
      context.fillStyle = "#fff";
      context.fillRect(0, 0, width, height);

      var color = this.colors[cIndex];
      var h = tsunami.geom.Point.polar(hypotenuse, color.angle * Math.PI / 180);
      var v = tsunami.geom.Point.polar(hypotenuse, (color.angle + 90) * Math.PI / 180);

      origin = new tsunami.geom.Point(width / 2 - h.x / 2 - v.x / 2, height / 2 - h.y / 2 - v.y / 2);

      context.fillStyle = color.hex;
      var rectangle = new tsunami.geom.Rectangle(-buffr, -buffr, width + buffr * 2, height + buffr * 2);

      for (var y = this.pixelsPerPoint / 2; y <= hypotenuse; y += this.pixelsPerPoint) {
        var yRatio = y / hypotenuse;
        var pos = new tsunami.geom.Point(v.x * yRatio, v.y * yRatio)
        for (var x = this.pixelsPerPoint / 2; x <= hypotenuse; x += this.pixelsPerPoint) {
          var xRatio = x / hypotenuse;
          var point = new tsunami.geom.Point(pos.x + h.x * xRatio + origin.x, pos.y + h.y * xRatio + origin.y);
          if (rectangle.contains(point)) {
            var pixel = Math.round(point.y) * width + Math.round(point.x);
            var dataIndex = pixel * 4;
            var pixelCMYK = this.rgb2cmyk(imageData.data[dataIndex], imageData.data[dataIndex + 1], imageData.data[dataIndex + 2]);
            var radius = this.pixelsPerPoint / 1.5 * pixelCMYK[color.name] / 100 * color.weight;
            if (radius > 0) {
              context.beginPath();
              context.arc(point.x + (-.5 + Math.random())* radius * 0.1, point.y + (-.5 + Math.random())* radius * 0.1, radius, 0 , 2 * Math.PI, false);
              context.fill();
            }
          }
        }
      }

      var src = ctx.getImageData(0, 0, width, height);
      var target = context.getImageData(0, 0, width, height);
      new tsunami.filters.Blendmode.multiply(src, target);
      ctx.putImageData(src, 0, 0);
    }


  }

  p.rgb2cmyk = function(r, g, b) {
    var computedC = 0;
    var computedM = 0;
    var computedY = 0;
    var computedK = 0;

    //remove spaces from input RGB values, convert to int
    //var r = parseInt( (''+r).replace(/\s/g,''),10 );
    //var g = parseInt( (''+g).replace(/\s/g,''),10 );
    //var b = parseInt( (''+b).replace(/\s/g,''),10 );

    // BLACK
    if (r==0 && g==0 && b==0) {
      computedC = 1;
      computedM = 1;
      computedY = 1;
      computedK = 1;
    } else {
      computedC = 1 - (r/255);
      computedM = 1 - (g/255);
      computedY = 1 - (b/255);
    }
    return {c:computedC * 100, m:computedM * 100, y:computedY * 100, k:computedK * 100};

  }

  p.clone = function() {
    return new HalftoneFilter(this.pixelsPerPoint);
  }

}());

(function() {

  tsunami.filters.ColorHalftoneFilterColor = function(name, hex, angle, weight) {
    this.name = name;
    this.hex = hex;
    this.angle = angle % 90;
    this.weight = weight;
  }

  var p = tsunami.filters.ColorHalftoneFilterColor.prototype;

  p.toString = function() {
    return "{ColorHalftoneFilterColor name:" + this.name + ", hex:" + this.hex + ", angle:" + this.angle + "}";
  }

}());
