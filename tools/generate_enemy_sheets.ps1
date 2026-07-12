Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = "Stop"

$sourceDir = Join-Path $PSScriptRoot "..\assets\characters"
$outDir = Join-Path $PSScriptRoot "..\assets\enemies"
$directions = @("s", "se", "e", "ne", "n")
$frameSize = 384

Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @"
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;
using System.Runtime.InteropServices;

public static class EnemySheetBuilder
{
    public static void Build(string inputPath, string outputPath, string kind, string direction)
    {
        using (var source = new Bitmap(inputPath))
        using (var bitmap = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb))
        {
            using (var g = Graphics.FromImage(bitmap))
            {
                g.Clear(Color.Transparent);
                g.DrawImage(source, 0, 0, source.Width, source.Height);
            }

            Recolor(bitmap, kind);
            DrawGear(bitmap, kind, direction);
            Directory.CreateDirectory(Path.GetDirectoryName(outputPath));
            bitmap.Save(outputPath, ImageFormat.Png);
        }
    }

    private static void Recolor(Bitmap bitmap, string kind)
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
                byte a = pixels[i + 3];
                if (a < 24) continue;

                bool skin = r > 130 && g > 78 && b > 58 && r > g + 28 && r > b + 38;
                bool hair = r < 95 && g < 75 && b < 65;
                if (skin)
                {
                    pixels[i + 0] = Clamp(b * 0.92 + 8);
                    pixels[i + 1] = Clamp(g * 0.92 + 6);
                    pixels[i + 2] = Clamp(r * 0.96);
                    continue;
                }

                int hash = (x * 17 + y * 31) & 15;
                double grime = hash == 0 ? 0.82 : (hash == 1 ? 0.9 : 1.0);
                if (kind == "melee")
                {
                    byte tr = hair ? (byte)35 : (byte)48;
                    byte tg = hair ? (byte)38 : (byte)55;
                    byte tb = hair ? (byte)42 : (byte)58;
                    pixels[i + 0] = Clamp((b * 0.45 + tb * 0.55) * grime);
                    pixels[i + 1] = Clamp((g * 0.45 + tg * 0.55) * grime);
                    pixels[i + 2] = Clamp((r * 0.45 + tr * 0.55) * grime);
                }
                else
                {
                    byte tr = hair ? (byte)60 : (byte)74;
                    byte tg = hair ? (byte)62 : (byte)82;
                    byte tb = hair ? (byte)58 : (byte)68;
                    pixels[i + 0] = Clamp((b * 0.50 + tb * 0.50) * grime);
                    pixels[i + 1] = Clamp((g * 0.50 + tg * 0.50) * grime);
                    pixels[i + 2] = Clamp((r * 0.50 + tr * 0.50) * grime);
                }
            }
        }

        Marshal.Copy(pixels, 0, data.Scan0, bytes);
        bitmap.UnlockBits(data);
    }

    private static byte Clamp(double value)
    {
        return (byte)Math.Max(0, Math.Min(255, (int)Math.Round(value)));
    }

    private static void DrawGear(Bitmap bitmap, string kind, string direction)
    {
        using (var g = Graphics.FromImage(bitmap))
        using (var outline = new Pen(Color.FromArgb(210, 18, 14, 12), 8))
        using (var bat = new Pen(Color.FromArgb(255, 96, 74, 48), 5))
        using (var gun = new Pen(Color.FromArgb(255, 32, 34, 36), 6))
        using (var bandage = new SolidBrush(Color.FromArgb(190, 198, 183, 158)))
        using (var pouch = new SolidBrush(Color.FromArgb(170, 77, 87, 63)))
        {
            g.SmoothingMode = System.Drawing.Drawing2D.SmoothingMode.AntiAlias;
            for (int frame = 0; frame < 16; frame++)
            {
                int ox = (frame % 4) * 384;
                int oy = (frame / 4) * 384;
                int gait = frame % 8;
                int sway = (gait == 2 || gait == 6) ? 5 : (gait == 3 || gait == 7 ? -4 : 0);

                if (kind == "melee")
                {
                    g.FillRectangle(bandage, ox + 171, oy + 138, 40, 9);
                    Point p1, p2;
                    switch (direction)
                    {
                        case "n": p1 = new Point(ox + 150 + sway, oy + 205); p2 = new Point(ox + 102 + sway, oy + 132); break;
                        case "ne": p1 = new Point(ox + 225 + sway, oy + 210); p2 = new Point(ox + 288 + sway, oy + 142); break;
                        case "e": p1 = new Point(ox + 230 + sway, oy + 215); p2 = new Point(ox + 315 + sway, oy + 202); break;
                        case "se": p1 = new Point(ox + 230 + sway, oy + 218); p2 = new Point(ox + 298 + sway, oy + 158); break;
                        default: p1 = new Point(ox + 236 + sway, oy + 220); p2 = new Point(ox + 298 + sway, oy + 146); break;
                    }
                    g.DrawLine(outline, p1, p2);
                    g.DrawLine(bat, p1, p2);
                }
                else
                {
                    g.FillRectangle(pouch, ox + 154, oy + 180, 70, 14);
                    Point p1, p2;
                    switch (direction)
                    {
                        case "n": p1 = new Point(ox + 155 + sway, oy + 198); p2 = new Point(ox + 120 + sway, oy + 172); break;
                        case "ne": p1 = new Point(ox + 226 + sway, oy + 203); p2 = new Point(ox + 268 + sway, oy + 180); break;
                        case "e": p1 = new Point(ox + 228 + sway, oy + 207); p2 = new Point(ox + 286 + sway, oy + 207); break;
                        case "se": p1 = new Point(ox + 226 + sway, oy + 210); p2 = new Point(ox + 272 + sway, oy + 228); break;
                        default: p1 = new Point(ox + 224 + sway, oy + 210); p2 = new Point(ox + 262 + sway, oy + 238); break;
                    }
                    g.DrawLine(outline, p1, p2);
                    g.DrawLine(gun, p1, p2);
                    g.FillEllipse(Brushes.Black, p2.X - 4, p2.Y - 4, 8, 8);
                }
            }
        }
    }
}
"@

foreach ($direction in $directions) {
	$source = Join-Path $sourceDir "survivor_anim_$direction.png"
	[EnemySheetBuilder]::Build($source, (Join-Path $outDir "enemy_melee_anim_$direction.png"), "melee", $direction)
	[EnemySheetBuilder]::Build($source, (Join-Path $outDir "enemy_pistol_anim_$direction.png"), "pistol", $direction)
}

Write-Host "Generated enemy animation sheets in $outDir"
