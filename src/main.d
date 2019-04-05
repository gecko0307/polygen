module main;

import std.stdio;
import std.range;
import std.string;
import std.getopt;

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
    string info = "Polygen - collision shape generator for Phaser 3 and Matter.js.\nUsage:\n   polygen [options] filename\n\nOptions:";

    uint step = 1;
    bool savePointsImage = false;

    try
    {
        auto helpInformation = getopt(
            args,
            "step", "Convex hull points traversal step (defaults to 1)", &step,
            "save", "Render convex hull points to out.png", &savePointsImage);

        if (helpInformation.helpWanted)
        {
            defaultGetoptPrinter(info,
            helpInformation.options);
            return;
        }
    }
    catch(Exception)
    {
        writeln("Illegal option");
        return;
    }

    string program = args[0];
    string[] targets = args[1..$];

    if (step == 0)
        step = 1;

    if (targets.length < 1)
    {
        writeln("Please, provide an image filename");
        return;
    }

    auto img = loadImage(targets[0]);
    auto imgbin = alphaBinarization(img);

    auto mat2d = Mat2D!ubyte(imgbin.data, imgbin.height, imgbin.width);
    auto rp = new RegionProps(mat2d, false);
    rp.calculateProps();

    SuperImage res = img.dup;
    Canvas canvas = new Canvas(res);
    canvas.lineColor = Color4f(1, 0, 0, 1);
    canvas.fillColor = Color4f(1, 0, 0, 1);

    // TODO: use json serializer instead of string formatting
    string fixtures = "";

    foreach(ri, region; rp.regions)
    {
        string points = "";

        for(size_t i = 0; i < region.convexHull.xs.length; i += step)
        {
            auto x = region.convexHull.xs[i];
            auto y = region.convexHull.ys[i];

            if (savePointsImage)
            {
                canvas.beginPath();
                canvas.pathMoveTo(x - 1, y - 1);
                canvas.pathLineTo(x + 1, y - 1);
                canvas.pathLineTo(x + 1, y + 1);
                canvas.pathLineTo(x - 1, y + 1);
                canvas.pathLineTo(x - 1, y - 1);
                canvas.pathFill();
                canvas.endPath();
            }

            if (i > 0)
                points ~= ", ";
            points ~= format("{ \"x\":%s, \"y\":%s }", x, y);
        }

        string fixture =
"
		{
			\"isSensor\": false,
			\"vertices\": [
				[%s]
			]
		}";

        if (ri > 0)
            fixtures ~= ",\n";
        fixtures ~= format(fixture, points);
    }

    string json =
"{
	\"type\": \"fromPhysicsEditor\",
	\"fixtures\": [
        %s
	]
}";

    if (savePointsImage)
        canvas.image.savePNG("out.png");

    string result = format(json, fixtures);
    writeln(result);
}
