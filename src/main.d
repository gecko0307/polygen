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
    auto _imgbin = alphaBinarization(img);

    auto imgbin = Mat2D!ubyte(_imgbin.data, _imgbin.height, _imgbin.width);
    auto rp = new RegionProps(imgbin, false);
    rp.calculateProps();

    SuperImage res = img.dup;
    Canvas canvas = new Canvas(res);
    canvas.lineColor = Color4f(1, 0, 0, 1);
    canvas.fillColor = Color4f(1, 0, 0, 1);

    size_t n = 4;

    string points = "";

    // TODO: multiple fixtures?
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

    string result = format(json, points);
    writeln(result);
}
