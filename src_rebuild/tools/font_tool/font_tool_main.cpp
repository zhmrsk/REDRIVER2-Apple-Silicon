#include <stdio.h>
#include <stdlib.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>

#define STB_TRUETYPE_IMPLEMENTATION
#include "stb_truetype.h"
#include "targa.h"

#include "hqfont.h"

struct FN2RangeInfo
{
	OUT_FN2RANGE hdr;
	OUT_FN2INFO* chars;
	int unicodeStart;
};

static FN2RangeInfo fontRanges[4];
static int fontRangeCount = 0;

static int GetCP1251Unicode(int c)
{
	if (c < 128) return c;
	if (c >= 192 && c <= 255) return 1040 + (c - 192);

	switch (c)
	{
		case 168: return 1025; // YO
		case 184: return 1105; // yo
		case 170: return 1028; // UKR YE
		case 186: return 1108; // ukr ye
		case 175: return 1031; // UKR YI
		case 191: return 1111; // ukr yi
		case 178: return 1030; // UKR I
		case 179: return 1110; // ukr i
		case 165: return 1168; // UKR G
		case 180: return 1169; // ukr g
	}
	
	// Fallback for other Cyrillic extension chars or unused slots
	// 0xA0 is NBSP (160)
	if (c == 160) return 0x00A0;
	
	return c; // usage of Latin glyphs for undefined CP1251 slots
}

void Usage()
{
	printf("example: FontTool -i <file.ttf> -o <name without ext>\n");
}

int main(int argc, char** argv)
{
	if (argc < 2)
	{
		Usage();
		return 0;
	}

	{
		FN2RangeInfo& firstRange = fontRanges[0];

		firstRange.hdr.start = 32;
		firstRange.hdr.count = 224;
		firstRange.unicodeStart = 32;
		firstRange.chars = new OUT_FN2INFO[firstRange.hdr.count];
		++fontRangeCount;
	}


	const char* inputFilename = nullptr;
	const char* outpitFilename = nullptr;

	for (int i = 0; i < argc; ++i)
	{
		if (!strcmp(argv[i], "-i") && i + 1 < argc)
		{
			inputFilename = argv[i+1];
		}
		else if (!strcmp(argv[i], "-o") && i + 1 < argc)
		{
			outpitFilename = argv[i + 1];
		}
	}


	if (!inputFilename)
	{
		Usage();
		return 0;
	}

	if (!outpitFilename)
	{
		Usage();
		return 0;
	}

	FILE* fp = fopen(inputFilename, "rb");
	if (!fp)
	{
		printf("Cannot open %s\n", inputFilename);
		return -1;
	}

	// read whole file
	fseek(fp, 0, SEEK_END);
	const long size = ftell(fp);
	fseek(fp, 0, SEEK_SET);
	u_char* data = (u_char*)malloc(size);
	fread(data, 1, size, fp);
	fclose(fp);

	// gen font
	u_char* tmpBitmap = (u_char*)malloc(HIRES_FONT_SIZE_W * HIRES_FONT_SIZE_H);
	u_int* bitmapRGBA = (u_int*)malloc(HIRES_FONT_SIZE_W * HIRES_FONT_SIZE_H * 4);

	stbtt_pack_context pc;
	stbtt_PackBegin(&pc, tmpBitmap, HIRES_FONT_SIZE_W, HIRES_FONT_SIZE_H, 0, 1, NULL);

	// Pack characters one by one to support custom mapping
	for (int i = 0; i < fontRangeCount; ++i)
	{
		FN2RangeInfo& range = fontRanges[i];
		
		for(int j = 0; j < range.hdr.count; j++)
		{
			int charCode = range.hdr.start + j;
			int unicode = GetCP1251Unicode(charCode);
			
			// pack single char
			// Note: stbtt_PackFontRange takes a range, so we pass count 1
			stbtt_PackFontRange(&pc, data, 0, 65.0f, unicode, 1, (stbtt_packedchar*)&range.chars[j]);
		}
	}
	
	stbtt_PackEnd(&pc);

	for (int x = 0; x < HIRES_FONT_SIZE_W; ++x)
	{
		for (int y = 0; y < HIRES_FONT_SIZE_H; ++y)
		{
			bitmapRGBA[x + y * HIRES_FONT_SIZE_W] = tmpBitmap[x + y * HIRES_FONT_SIZE_W] << 24 | 0xffffff;
		}
	}

	{
		char tgaFileName[256];
		strcpy(tgaFileName, outpitFilename);
		strcat(tgaFileName, ".tga");

		SaveTGAImage(tgaFileName, (u_char*)bitmapRGBA, HIRES_FONT_SIZE_W, HIRES_FONT_SIZE_H, 32);
	}

	{
		char fntFileName[256];
		strcpy(fntFileName, outpitFilename);
		strcat(fntFileName, ".fn2");

		FILE* fntFp = fopen(fntFileName, "wb");
		if (fntFp)
		{
			OUT_FN2HEADER fn2hdr;
			fn2hdr.version = FN2_VERSION;
			fn2hdr.range_count = fontRangeCount;
			fwrite(&fn2hdr, sizeof(fn2hdr), 1, fntFp);

			for (int i = 0; i < fontRangeCount; ++i)
			{
				FN2RangeInfo& range = fontRanges[i];
				fwrite(&range.hdr, sizeof(OUT_FN2RANGE), 1, fntFp);
				fwrite(range.chars, sizeof(OUT_FN2INFO), range.hdr.count, fntFp);

				delete[] range.chars;
			}
		}
	}

	free(bitmapRGBA);
	free(tmpBitmap);
	free(data);
}