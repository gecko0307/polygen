module main;

import std.stdio;
import std.range;
import std.string;

import dlib.image;

import measure.regionprops;
import measure.types;

SuperImage alphaBinarization(SuperImage img, float alphaThreshold = 0.0f)
{
    SuperImage res = image(img.width, img.height, 1);

    foreach (x; 0..img.width)
	foreach (y; 0..img.height)
	{
        float alpha = img[x, y].a;
		res[x, y] = (alpha > alphaThreshold)? Color4f(1, 1, 1, 1) : Color4f(0, 0, 0, 1);
	}

    return res;
}

void main(string[] args)
{
    if (args.length < 1)
        return;

    auto img = loadPNG(args[1]);
    auto imgbin = alphaBinarization(img);

    auto mat2d = Mat2D!ubyte(imgbin.data, imgbin.height, imgbin.width);
    auto rp = new RegionProps(mat2d, false);
    rp.calculateProps();

    SuperImage res = img.dup;
    Canvas canvas = new Canvas(res);
    canvas.lineColor = Color4f(1, 0, 0, 1);
    canvas.fillColor = Color4f(1, 0, 0, 1);

    size_t n = 2;

    string points = "";

    // TODO: multiple fixtures?
    // TODO: n as argument
    foreach(ri, region; rp.regions)
    {
        for(size_t i = 0; i < region.convexHull.xs.length; i += n)
        {
            auto x = region.convexHull.xs[i];
            auto y = region.convexHull.ys[i];

            canvas.beginPath();
            canvas.pathMoveTo(x - 1, y - 2);
            canvas.pathLineTo(x + 1, y - 2);
            canvas.pathLineTo(x + 1, y + 1);
            canvas.pathLineTo(x - 1, y + 1);
            canvas.pathLineTo(x - 1, y - 2);
            canvas.pathFill();
            canvas.endPath();

            if (i > 0)
                points ~= ", ";
            points ~= format("{ \"x\":%s, \"y\":%s }", x, y);
        }
    }

    string json =
"{
	\"type\": \"fromPhysicsEditor\",
	\"fixtures\": [
		{
			\"isSensor\": false,
			\"vertices\": [
				[%s]
			]
		}
	]
}";

    // TODO: make this optional
    canvas.image.savePNG("out.png");

    string result = format(json, points);
    writeln(result);
}
