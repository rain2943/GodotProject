Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$enemyDir = Join-Path $PSScriptRoot "..\assets\enemies"
$frameSize = 384
$directions = @("s", "se", "e", "ne", "n")

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class EnemyConceptSheetBuilder
{
    public static void Build(string sourcePath, string outPath, string direction)
    {
        using (var original = new Bitmap(sourcePath))
        using (var cutout = ExtractCutout(original))
        using (var sheet = new Bitmap(1536, 1536, PixelFormat.Format32bppArgb))
        {
            using (var g = Graphics.FromImage(sheet))
            {
                g.Clear(Color.Transparent);
                g.InterpolationMode = InterpolationMode.HighQualityBicubic;
                g.SmoothingMode = SmoothingMode.AntiAlias;
                g.PixelOffsetMode = PixelOffsetMode.HighQuality;

                for (int frame = 0; frame < 16; frame++)
                {
                    int col = frame % 4;
                    int row = frame / 4;
                    bool walk = frame >= 8;
                    int cycle = frame % 8;
                    float bob = walk ? ((cycle == 1 || cycle == 5) ? -5f : ((cycle == 3 || cycle == 7) ? 4f : 0f)) : 0f;
                    float sway = walk ? ((cycle == 2 || cycle == 6) ? 5f : ((cycle == 4) ? -4f : 0f)) : 0f;
                    DrawFrame(g, cutout, direction, col * 384, row * 384, sway, bob, walk);
                }
            }
            Directory.CreateDirectory(Path.GetDirectoryName(outPath));
            sheet.Save(outPath, ImageFormat.Png);
        }
    }

    private static Bitmap ExtractCutout(Bitmap source)
    {
        var rect = FindSubjectBounds(source);
        rect.Inflate(18, 18);
        rect.Intersect(new Rectangle(0, 0, source.Width, source.Height));
        var target = new Bitmap(rect.Width, rect.Height, PixelFormat.Format32bppArgb);
        using (var g = Graphics.FromImage(target))
        {
            g.Clear(Color.Transparent);
            g.DrawImage(source, new Rectangle(0, 0, rect.Width, rect.Height), rect, GraphicsUnit.Pixel);
        }
        RemoveGreen(target);
        return target;
    }

    private static Rectangle FindSubjectBounds(Bitmap source)
    {
        int minX = source.Width, minY = source.Height, maxX = 0, maxY = 0;
        for (int y = 0; y < source.Height; y++)
        {
            for (int x = 0; x < source.Width; x++)
            {
                var c = source.GetPixel(x, y);
                if (!IsGreenKey(c))
                {
                    minX = Math.Min(minX, x);
                    minY = Math.Min(minY, y);
                    maxX = Math.Max(maxX, x);
                    maxY = Math.Max(maxY, y);
                }
            }
        }
        if (minX > maxX) return new Rectangle(0, 0, source.Width, source.Height);
        return Rectangle.FromLTRB(minX, minY, maxX + 1, maxY + 1);
    }

    private static void RemoveGreen(Bitmap bitmap)
    {
        var rect = new Rectangle(0, 0, bitmap.Width, bitmap.Height);
        var data = bitmap.LockBits(rect, ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
        int bytes = Math.Abs(data.Stride) * data.Height;
        byte[] pixels = new byte[bytes];
        Marshal.Copy(data.Scan0, pixels, 0, bytes);
        for (int y = 0; y < bitmap.Height; y++)
        {
            int row = y * data.Stride;
            for (int x = 0; x < bitmap.Width; x++)
            {
                int i = row + x * 4;
                byte b = pixels[i + 0];
                byte g = pixels[i + 1];
                byte r = pixels[i + 2];
                if (IsGreenKey(r, g, b))
                {
                    pixels[i + 3] = 0;
                    continue;
                }
                if (g > r + 35 && g > b + 35)
                {
                    pixels[i + 1] = (byte)Math.Max((r + b) / 2, g - 55);
                }
            }
        }
        Marshal.Copy(pixels, 0, data.Scan0, bytes);
        bitmap.UnlockBits(data);
    }

    private static bool IsGreenKey(Color c)
    {
        return IsGreenKey(c.R, c.G, c.B);
    }

    private static bool IsGreenKey(int r, int g, int b)
    {
        return g > 165 && r < 90 && b < 105 && g > r * 1.7 && g > b * 1.45;
    }

    private static void DrawFrame(Graphics g, Bitmap cutout, string direction, int x, int y, float sway, float bob, bool walk)
    {
        float targetHeight = direction == "n" ? 252f : 266f;
        float scale = targetHeight / cutout.Height;
        float width = cutout.Width * scale;
        float height = cutout.Height * scale;
        float squash = 1f;
        bool flip = false;
        float alpha = 1f;

        switch (direction)
        {
            case "n":
                squash = 0.86f;
                alpha = 0.88f;
                break;
            case "ne":
                squash = 0.9f;
                flip = true;
                break;
            case "e":
                squash = 0.78f;
                flip = true;
                break;
            case "se":
                squash = 0.9f;
                flip = true;
                break;
        }

        width *= squash;
        float centerX = x + 192f + sway;
        float footY = y + 340f + bob;
        var dest = new RectangleF(centerX - width * 0.5f, footY - height, width, height);

        using (var shadow = new SolidBrush(Color.FromArgb(55, 0, 0, 0)))
        {
            g.FillEllipse(shadow, x + 132, y + 322, 120, 24);
        }

        var oldState = g.Save();
        if (flip)
        {
            g.TranslateTransform(dest.X + dest.Width * 0.5f, dest.Y + dest.Height * 0.5f);
            g.ScaleTransform(-1, 1);
            g.TranslateTransform(-(dest.X + dest.Width * 0.5f), -(dest.Y + dest.Height * 0.5f));
        }

        using (var attributes = new ImageAttributes())
        {
            var matrix = new ColorMatrix();
            matrix.Matrix33 = alpha;
            if (direction == "n")
            {
                matrix.Matrix00 = 0.68f;
                matrix.Matrix11 = 0.72f;
                matrix.Matrix22 = 0.76f;
            }
            attributes.SetColorMatrix(matrix, ColorMatrixFlag.Default, ColorAdjustType.Bitmap);
            g.DrawImage(cutout, Rectangle.Round(dest), 0, 0, cutout.Width, cutout.Height, GraphicsUnit.Pixel, attributes);
        }
        g.Restore(oldState);

    }
}
"@

$sources = @{
	"melee" = "enemy_melee_concept.png"
	"pistol" = "enemy_pistol_concept.png"
}

foreach ($kind in $sources.Keys) {
	$source = Join-Path $enemyDir $sources[$kind]
	foreach ($direction in $directions) {
		$outPath = Join-Path $enemyDir "enemy_${kind}_anim_${direction}.png"
		[EnemyConceptSheetBuilder]::Build($source, $outPath, $direction)
	}
}

Write-Host "Generated concept enemy animation sheets in $enemyDir"
