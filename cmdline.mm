#import <Foundation/Foundation.h>
#import "utils.h"

#define OSD 1

int cmdline_main(int argc, const char * argv[])
{
    NSAutoreleasePool* pool = [NSAutoreleasePool new];
    {
        int width = 0;
        int height = 0;
        CGFloat scale = 0.0f;
        int freq;
        int bitRes = 0;
        int displayId = -1;
        int displayNo = -1;
        int rotation = -1;
        
        bool interlaced = 0;
        
        bool listDisplays = 0;
        bool listModes = 0;
        bool listCommands = 0;
        
        bool useOsd = 0;
        
        int usermode = -1;
        
        for (int i=1; i<argc; i++)
        {
            if (argv[i][0]=='-')
            {
                if (strlen(argv[i])==2)
                {
                    switch(argv[i][1])
                    {
                        case 'm':
                            i++;
                            if (i >= argc) return -1;
                            usermode = atoi(argv[i]);
                            break;
                        case 'w':
                            i++;
                            if (i >= argc) return -1;
                            width = atoi(argv[i]);
                            break;
                        case 'h':
                            i++;
                            if (i >= argc) return -1;
                            height = atoi(argv[i]);
                            break;
                        case 's':
                            i++;
                            if (i >= argc) return -1;
                            scale = atof (argv[i]);
                            break;
                        case 'f':
                            i++;
                            if (i >= argc) return -1;
                            freq = atof (argv[i]);
                            break;
                        case 'i':
                            interlaced = 1;
                            break;
                        case 'b':
                            i++;
                            if (i >= argc) return -1;
                            bitRes = atoi(argv[i]);
                            break;
                        case 'd':
                            i++;
                            if (i >= argc) return -1;
							if (strncmp(argv[i], "0x", 2) == 0)
		                        displayId = (int)strtol(argv[i], NULL, 0);
							else
		                        displayNo = atoi(argv[i]);
                            break;
                        case 'l':
                            if (argv[i][2]=='m')
                                listModes = 1;
                            if (argv[i][2]=='d')
                                listDisplays = 1;
                            if (argv[i][2]=='c')
                                listCommands = 1;
                            break;
                        case 'r':
                            i++;
                            if (i >= argc) return -1;
                            rotation = atof (argv[i]);
                            break;
#ifdef OSD
                        case 'o':
                            useOsd = 1;
                            break;
#endif
                        default:
                            return -1;
                    }
                    continue;
                }
                if (argv[i][1]=='l' && strlen(argv[i])==3)
                {
                    if (argv[i][2]=='m')
                        listModes = 1;
                    else if (argv[i][2]=='d')
                        listDisplays = 1;
                    else if (argv[i][2]=='c')
                        listCommands = 1;
                    else
                        return -1;
                    continue;
                }
                if (argv[i][1]=='-')
                {
                    if (!strcmp(&argv[i][2], "mode"))
                    {
                        i++;
                        if (i >= argc) return -1;
                        usermode = atoi(argv[i]);
                    }
                    else if (!strcmp(&argv[i][2], "width"))
                    {
                        i++;
                        if (i >= argc) return -1;
                        width = atoi(argv[i]);
                    }
                    else if (!strcmp(&argv[i][2], "height"))
                    {
                        i++;
                        if (i >= argc) return -1;
                        height = atoi(argv[i]);
                    }
                    else if (!strcmp(&argv[i][2], "scale"))
                    {
                        i++;
                        if (i >= argc) return -1;
                        scale = atof (argv[i]);
                    }
                    else if (!strcmp(&argv[i][2], "freq"))
                    {
                        i++;
                        if (i >= argc) return -1;
                        freq = atof (argv[i]);
                    }
                    else if (!strcmp(&argv[i][2], "bits"))
                    {
                        i++;
                        if (i >= argc) return -1;
                        bitRes = atoi(argv[i]);
                    }
                    else if (!strcmp(&argv[i][2], "interlaced"))
                    {
                        interlaced = 1;
                    }
                    else if (!strcmp(&argv[i][2], "display"))
                    {
                        i++;
                        if (i >= argc) return -1;
                        if (strncmp(argv[i], "0x", 2) == 0)
                            displayId = (int)strtol(argv[i], NULL, 0);
                        else
                            displayNo = atoi(argv[i]);
                    }
                    else if (!strcmp(&argv[i][2], "displays"))
                    {
                        listDisplays = 1;
                    }
                    else if (!strcmp(&argv[i][2], "modes"))
                    {
                        listModes = 1;
                    }
                    else if (!strcmp(&argv[i][2], "commands"))
                    {
                        listCommands = 1;
                    }
                    else if (!strcmp(&argv[i][2], "rotation"))
                    {
                        i++;
                        if (i >= argc) return -1;
                        rotation = atof (argv[i]);
                    }
#ifdef OSD
                    else if (!strcmp(&argv[i][2], "osd"))
                    {
                        useOsd = 1;
                    }
#endif
                    else
                    {
                        return -1;
                    }
                    continue;
                }
                return -1;
            }
            return -1;
        }
        
        uint32_t nDisplays;
        CGDirectDisplayID displays[0x10];
        CGGetOnlineDisplayList(0x10, displays, &nDisplays);
        
        //displays[0] = CGMainDisplayID();
        
        
        CGDirectDisplayID display;

        if (displayId != -1 && displayNo == -1)
        {
            for (int i=0; i<nDisplays; i++)
            {
                if (displays[i] == displayId)
                    displayNo=i;
            }
            if (displayNo == -1)
            {
                fprintf (stderr, "Error: display id 0x%02x unknown\n", displayId);
                exit(1);
            }
        }

        if (displayNo > 0)
        {
            if (displayNo > nDisplays -1)
            {
                fprintf (stderr, "Error: display index %d exceeds display count %d\n", displayNo, nDisplays);
                exit(1);
            }
            display = displays[displayNo];
        }
        else
        {
            display = CGMainDisplayID();
        }

        if (listDisplays)
        {
            for (int i=0; i<nDisplays; i++)
            {
                int modeNum;
                CGSGetCurrentDisplayMode(displays[i], &modeNum);
                modes_D4 mode;
                CGSGetDisplayModeDescriptionOfLength(displays[i], modeNum, &mode, 0xD4);
                
                int mBitres = (mode.derived.depth == 4) ? 32 : 16;
                interlaced = ((mode.derived.flags & kDisplayModeInterlacedFlag) == kDisplayModeInterlacedFlag);
                
                fprintf (stdout, "Display %d: { id = 0x%02x,  resolution = %dx%d,  scale = %.1f,  freq = %d,  bits/pixel = %d%s }\n", i, displays[i], mode.derived.width, mode.derived.height, mode.derived.density, mode.derived.freq, mBitres, (interlaced ? ", interlaced" : ""));
                
            }
            
            return 0;
        }

        if (listModes)
        {
            int nModes;
            modes_D4* modes;
            CopyAllDisplayModes(display, &modes, &nModes);
            
            fprintf (stdout, "mode\tresolution\tscale\tfreq\tbits/pixel\n*****************************************************\n");
            for (int i=0; i<nModes; i++)
            {
                modes_D4 mode = modes[i];
                if (width && mode.derived.width != width)
                    continue;
                if (height && mode.derived.height != height)
                    continue;
                if (scale && mode.derived.density != scale)
                    continue;
                if (freq && mode.derived.freq != freq)
                    continue;
                int mBitres = (mode.derived.depth == 4) ? 32 : 16;
                if (bitRes && mBitres != bitRes)
                    continue;
                
                interlaced = ((mode.derived.flags & kDisplayModeInterlacedFlag) == kDisplayModeInterlacedFlag);
                fprintf (stdout, "%2d\t%dx%d  \t%.1f\t%d\t%d%s\n", i, mode.derived.width, mode.derived.height, mode.derived.density, mode.derived.freq, mBitres, (interlaced ? " interlaced" : ""));
            }
            
            free(modes);
            
            return 0;
        }
        
        if (listCommands)
        {
            int nModes;
            modes_D4* modes;
            CopyAllDisplayModes(display, &modes, &nModes);
            
            fprintf (stdout, "Available command-lines\n******************************************\n");
            for (int i=0; i<nModes; i++)
            {
                modes_D4 mode = modes[i];
                if (width && mode.derived.width != width)
                    continue;
                if (height && mode.derived.height != height)
                    continue;
                if (scale && mode.derived.density != scale)
                    continue;
                if (freq && mode.derived.freq != freq)
                    continue;
                int mBitres = (mode.derived.depth == 4) ? 32 : 16;
                if (bitRes && mBitres != bitRes)
                    continue;
                
                interlaced = ((mode.derived.flags & kDisplayModeInterlacedFlag) == kDisplayModeInterlacedFlag);
                if (displayNo > 0)
	                {
	                    fprintf (stdout, "-d %d -w %d -h %d -s %.0f%s -f %d -b %d\n", displayNo, mode.derived.width, mode.derived.height, mode.derived.density, (interlaced ? " -i" : ""), mode.derived.freq, mBitres);
	                    fprintf (stdout, "-d 0x%02x -w %d -h %d -s %.0f%s -f %d -b %d\n", displays[i], mode.derived.width, mode.derived.height, mode.derived.density, (interlaced ? " -i" : ""), mode.derived.freq, mBitres);
	                }
                else
                    fprintf (stdout, "-w %d -h %d -s %.0f%s -f %d -b %d\n", mode.derived.width, mode.derived.height, mode.derived.density, (interlaced ? " -i" : ""), mode.derived.freq, mBitres);
                
            }
            
            free(modes);
            
            return 0;
        }
        
        if (rotation != -1)
        {
            //io_service_t service = CGDisplayIOServicePort(display);
            io_service_t service = IOServicePortFromCGDisplayID(display);
            
            IOOptionBits options;
            
            switch(rotation)
            {
                default:
                    options = (0x00000400 | (kIOScaleRotate0)  << 16);
                    break;
                case 90:
                    options = (0x00000400 | (kIOScaleRotate90)  << 16);
                    break;
                case 180:
                    options = (0x00000400 | (kIOScaleRotate180)  << 16);
                    break;
                case 270:
                    options = (0x00000400 | (kIOScaleRotate270)  << 16);
                    break;
            }
            
            int retVal = IOServiceRequestProbe(service, options);

            IOObjectRelease(service);
            
            if (retVal != 0)
                fprintf(stderr, "Error rotating display %i\n", display);
            
            usleep(kRotationDelay);
        }
        
        // find best mode for scale
        if (scale && !width && !height) {
            
            double aspectRatio = 0.0;

            { // fill aspect ratio from first mode
                int modeNum = 0;
                //CGSGetCurrentDisplayMode(display, &modeNum); // uncomment to get the current mode
                modes_D4 mode;
                CGSGetDisplayModeDescriptionOfLength(display, modeNum, &mode, 0xD4);
                aspectRatio = ((double)mode.derived.width / (double)mode.derived.height);
                if (!freq) freq = mode.derived.freq;
                if (!bitRes) bitRes = (mode.derived.depth == 4) ? 32 : 16;
            }

            int nModes;
            modes_D4* modes;
            CopyAllDisplayModes(display, &modes, &nModes);

            for (int i=0; i<nModes; i++)
            {
                modes_D4 mode = modes[i];

                if (scale && mode.derived.density != scale)
                    continue;
                if (freq && mode.derived.freq != freq)
                    continue;
                if (!interlaced && ((mode.derived.flags & kDisplayModeInterlacedFlag) == kDisplayModeInterlacedFlag))
                    continue;
                int mBitres = (mode.derived.depth == 4) ? 32 : 16;
                if (bitRes && mBitres != bitRes)
                    continue;
                if (width && mode.derived.width < width)
                    continue;
                if (((double)mode.derived.width / (double)mode.derived.height) != aspectRatio)
                    continue;
                
                width = mode.derived.width;
                height = mode.derived.height;
            }
            
            free(modes);
        }
        
        // fill in missing details
        {
            int modeNum;
            CGSGetCurrentDisplayMode(display, &modeNum);
            modes_D4 mode;
            CGSGetDisplayModeDescriptionOfLength(display, modeNum, &mode, 0xD4);
            
            if (!width && !height)
            {
                width = mode.derived.width;
                height = mode.derived.height;
            }
            if (!scale)
            {
                scale = mode.derived.density;
            }
            int mBitres = (mode.derived.depth == 4) ? 32 : 16;
            if (!bitRes)
            {
                bitRes = mBitres;
            }
        }
        
        
        {
            int nModes;
            modes_D4* modes;
            CopyAllDisplayModes(display, &modes, &nModes);
            
            int iMode = -1;
            
            if (usermode >= 0 && usermode < nModes) {
                iMode = usermode;
#ifdef OSD
                if (useOsd) {
                    modes_D4 mode;
                    CGSGetDisplayModeDescriptionOfLength(display, usermode, &mode, 0xD4);
                    width = mode.derived.width;
                    height = mode.derived.height;
                    scale = mode.derived.density;
                }
#endif
            } else
                
            for (int i=0; i<nModes; i++)
            {
                modes_D4 mode = modes[i];
                
                if (width && mode.derived.width != width)
                    continue;
                if (height && mode.derived.height != height)
                    continue;
                if (scale && mode.derived.density != scale)
                    continue;
                if (freq && mode.derived.freq != freq)
                    continue;
                if (!interlaced && ((mode.derived.flags & kDisplayModeInterlacedFlag) == kDisplayModeInterlacedFlag))
                    continue;
                int mBitres = (mode.derived.depth == 4) ? 32 : 16;
                if (bitRes && mBitres != bitRes)
                    continue;
                
                iMode = i;
                break;
            }
            
            if (iMode != -1)
            {
                SetDisplayModeNum(display, iMode);
#ifdef OSD
                if (useOsd) {
                    usleep(100000);
                    NSString *OSDisplay = @"/Applications/OSDisplay.app/Contents/MacOS/OSDisplay";
                    [NSTask launchedTaskWithLaunchPath:OSDisplay arguments:[NSArray arrayWithObjects:
                                                                            @"-m", [NSString stringWithFormat:@"%dx%d%@", width, height, (scale > 1) ? @" HiDPI" : @""],
                                                                            @"-i", @"monitor", nil]];
                    
                }
#endif
            }
            else
            {
                fprintf (stderr, "Error: could not select a new mode\n");
            }
            
            free(modes);
        }
        
        
    }
    [pool release];
    return 0;
}
