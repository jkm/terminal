// Copyright Jens K. Mueller
// Boost License 1.0

// TODO
// what licence am I allowed to use


// easy use by writec* in write fashion
// using the shared terminals
// or using .backgroundColor = Color.black

// TODO
// how get unset attributes like bold etc. on Posix
// TODO
// how to properly test this module

module terminal;

import std.string;
import std.exception : enforce, errnoEnforce;
import std.conv;

// TODO
// move to src/core/sys/windows/windows.d
version(Windows)
{
	enum
	{
		COMMON_LVB_REVERSE_VIDEO = 0x4000, //
		COMMON_LVB_UNDERSCORE    = 0x8000, //
	}
}

__gshared
{
	Terminal stdout;
	Terminal stderr;
}

static this()
{
	stdout = Terminal(std.stdio.stdout);
	stderr = Terminal(std.stdio.stderr);
}

static ~this()
{
	stdout.restoreDefaults();
	stderr.restoreDefaults();
}


/// Terminal colors
enum Color
{
	black   = 0,
	red     = 1,
	green   = 2,
	yellow  = 3,
	blue    = 4,
	magenta = 5,
	cyan    = 6,
	white   = 7,
}

/// Return the name of the terminal.
@property
string name()
{
	version(Posix)
	{
		return std.process.getenv("TERM");
	}
	else version(Windows)
	{
		return "Windows";
	}
	else static assert(0, NOT_IMPLEMENTED);
}

unittest
{
	version(Posix)
	{
		assert(terminal.name == std.process.getenv("TERM"));
	}
	else version(Windows)
	{
		assert(terminal.name == "Windows");
	}
}

/// Return true if terminal supports colors. Otherwise false.
@property
bool hasColors()
{
	version(Posix)
	{
		return hasCapability(Capability.foreground) &&
			   hasCapability(Capability.background);
	}
	else version(Windows)
	{
		return true;
	}
	else static assert(0, NOT_IMPLEMENTED);
}

unittest
{
	// test color support here
	assert(hasColors == true);
}

/// Return true if terminal supports bold font. Otherwise false.
@property
bool hasCapability(in Capability capability)
{
	version(Posix)
	{
		return capabilities[capability] != null;
	}
	else version(Windows)
	{
		// TODO
		return true;
	}
	else static assert(0, NOT_IMPLEMENTED);
}

/// Return number of lines.
@property
int lines()
{
	// TODO
	// windows
	return tgetnum(toStringz("li"));
}

unittest
{
	writeln("#Lines is ", terminal.lines);
}

/// Return number of columns.
@property
int columns()
{
	// TODO
	// windows
	return tgetnum(toStringz("co"));
}

unittest
{
	writeln("#Columns is ", columns);
}

void writecf(T...)(in Color color, T args)
{
	auto oldColor = stdout.foregroundColor(color);
	scope(exit) stdout.foregroundColor(oldColor);
	writef(args);
}

unittest
{
	foreach (color; __traits(allMembers, Color))
		writecf(mixin("Color." ~ color), "%s ", color);
	writeln();
}

void writecfln(T...)(in Color color, T args)
{
	auto oldColor = stdout.foregroundColor(color);
	scope(exit) stdout.foregroundColor(oldColor);
	writefln(args);
}

unittest
{
	foreach (color; __traits(allMembers, Color))
		writecf(mixin("Color." ~ color), "%s ", color);
	writeln();
}

void writec(T...)(in Color color, T args)
{
	auto oldColor = stdout.foregroundColor(color);
	scope(exit) stdout.foregroundColor(oldColor);
	write(args);
}

unittest
{
	foreach (color; __traits(allMembers, Color))
		writecf(mixin("Color." ~ color), "%s ", color);
	writeln();
}

void writecln(T...)(in Color color, T args)
{
	auto oldColor = stdout.foregroundColor(color);
	scope(exit) stdout.foregroundColor(oldColor);
	writeln(args);
}

unittest
{
	foreach (color; __traits(allMembers, Color))
		writecf(mixin("Color." ~ color), "%s ", color);
	writeln();
}

private:

// terminal capabilities
enum Capability
{
	foreground,
	background,
	boldFace,
	blinkFace,
	reverseFace,
	underlineFace,
	allOff,
}

version(Posix)
{
	enum PosixCapability = [
		Capability.foreground    : "setaf",
		Capability.background    : "setab",
		Capability.boldFace      : "bold",
		Capability.blinkFace     : "blink",
		Capability.reverseFace   : "rev",
		Capability.underlineFace : "smul",
		Capability.allOff        : "sgr0", // turns all attributes off
	];

	enum numCapabilities = Capability.max - Capability.min + 1;
	static assert(capabilities.length == numCapabilities);
	static const(char)* capabilities[numCapabilities];

	// TODO
	// move to druntime
	// POSIX.1-2001.
	extern(C) int isatty(int fd);
}
else version(Windows)
{
	import core.sys.windows.windows;
	import std.windows.syserror;
	extern(C) int _isatty(int fd);
	alias _isatty isatty;

	enum WORD[Color] WindowsForegroundColor = [
		Color.black   : 0,
		Color.red     : FOREGROUND_RED,
		Color.green   : FOREGROUND_GREEN,
		Color.yellow  : FOREGROUND_RED | FOREGROUND_GREEN,
		Color.blue    : FOREGROUND_BLUE,
		Color.magenta : FOREGROUND_RED | FOREGROUND_BLUE,
		Color.cyan    : FOREGROUND_BLUE | FOREGROUND_GREEN,
		Color.white   : FOREGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_RED,
	];

	enum Color[WORD] WindowsForegroundColorReverse = [
		0                                                   : Color.black,
		FOREGROUND_RED                                      : Color.red,
		FOREGROUND_GREEN                                    : Color.green,
		FOREGROUND_RED | FOREGROUND_GREEN                   : Color.yellow,
		FOREGROUND_BLUE                                     : Color.blue,
		FOREGROUND_RED | FOREGROUND_BLUE                    : Color.magenta,
		FOREGROUND_BLUE | FOREGROUND_GREEN                  : Color.cyan,
		FOREGROUND_BLUE | FOREGROUND_GREEN | FOREGROUND_RED : Color.white,
	];

	enum WORD[Color] WindowsBackgroundColor = [
		Color.black   : 0,
		Color.red     : BACKGROUND_RED,
		Color.green   : BACKGROUND_GREEN,
		Color.yellow  : BACKGROUND_RED | BACKGROUND_GREEN,
		Color.blue    : BACKGROUND_BLUE,
		Color.magenta : BACKGROUND_RED | BACKGROUND_BLUE,
		Color.cyan    : BACKGROUND_BLUE | BACKGROUND_GREEN,
		Color.white   : BACKGROUND_BLUE | BACKGROUND_GREEN | BACKGROUND_RED,
	];

	enum Color[WORD] WindowsBackgroundColorReverse = [
		0                                                   : Color.black,
		BACKGROUND_RED                                      : Color.red,
		BACKGROUND_GREEN                                    : Color.green,
		BACKGROUND_RED | BACKGROUND_GREEN                   : Color.yellow,
		BACKGROUND_BLUE                                     : Color.blue,
		BACKGROUND_RED | BACKGROUND_BLUE                    : Color.magenta,
		BACKGROUND_BLUE | BACKGROUND_GREEN                  : Color.cyan,
		BACKGROUND_BLUE | BACKGROUND_GREEN | BACKGROUND_RED : Color.white,
	];
}

import std.stdio;

enum NOT_IMPLEMENTED = "Not implemented for your OS. Please file an enhancement request.";

struct Terminal
{
	this(File file)
	in
	{
		assert(file == std.stdio.stdout || file == std.stdio.stderr);
	}
	body
	{
		static initialized = false;

		if (!initialized)
		{
			version(Posix)
			{
				// TODO
				// do I have to initialize it on stderr as well
				// initialize terminfo
				enforce(!setupterm(null, core.stdc.stdio.fileno(core.stdc.stdio.stdout), null));

				// initialize all capabilities
				foreach (cap; __traits(allMembers, Capability))
				{
					enum capability = mixin("Capability"~"."~cap);
					enum capabilityString = PosixCapability[capability];
					auto str = tigetstr(toStringz(capabilityString));
					assert(str != cast(const(char)*)-1, format("%s is not a string capability", capabilityString));
					capabilities[capability] = str;
				}
			}
		}

		_file = file;
		version(Windows) _startUpAttributes = getCharacterAttributes();
	}

	/// Set the terminal's foreground color. Return old foreground color (see
	/// foregroundColor()).
	@property
	Color foregroundColor(in Color color)
	{
		auto oldColor = foregroundColor();
		setCapability(Capability.foreground, color);
		return oldColor;
	}

	/// Return the terminal's current foreground color. On Posix systems the
	/// color will be the terminal's default color.
	@property
	Color foregroundColor() const
	{
		version(Posix)
		{
			// TODO
			// is this standard compliant
			// how get the default color?
			// what about capability with name op (see man 5 terminfo)
			return cast(Color) 9;
		}
		else version(Windows)
		{
			WORD characterAttributes = getCharacterAttributes() & 0x0007;
			return WindowsForegroundColorReverse[characterAttributes];
		}
		else static assert(0, NOT_IMPLEMENTED);
	}

	unittest
	{
		write("Foreground: ");
		foreach (color; __traits(allMembers, Color))
		{
			auto oldColor = stdout.foregroundColor(mixin("Color." ~ color));
			scope(exit) stdout.foregroundColor(oldColor);
			writef("%s ", color);
		}
		writeln();
	}

	/// Set the terminal's background color. Return old background color (see
	/// backgroundColor()).
	@property
	Color backgroundColor(in Color color)
	{
		auto oldColor = backgroundColor();
		setCapability(Capability.background, color);
		return oldColor;
	}

	/// Return the terminal's current background color. On Posix systems the
	/// color will be the terminal's default color.
	@property
	Color backgroundColor() const
	{
		version(Posix)
		{
			// TODO
			return cast(Color) 9;
		}
		else version(Windows)
		{
			WORD characterAttributes = getCharacterAttributes() & 0x0070;
			return WindowsBackgroundColorReverse[characterAttributes];
		}
		else static assert(0, NOT_IMPLEMENTED);
	}

	unittest
	{
		write("Background: ");
		foreach (color; __traits(allMembers, Color))
		{
			auto oldColor = stdout.backgroundColor(mixin("Color." ~ color));
			writef("%s", color);
			stdout.backgroundColor(oldColor);
			write(" ");
		}
		writeln();
	}

	unittest
	{
		writeln("Background\\Foreground:");
		foreach (backgroundColor; __traits(allMembers, Color))
		{
			writef("%10s: ", backgroundColor);
			auto oldBackgroundColor = stdout.backgroundColor(mixin("Color." ~ backgroundColor));
			foreach (foregroundColor; __traits(allMembers, Color))
			{
				auto oldForegroundColor = stdout.foregroundColor(mixin("Color." ~ foregroundColor));
				scope(exit) stdout.foregroundColor(oldForegroundColor);
				writef("%s ", foregroundColor);
			}
			stdout.backgroundColor(oldBackgroundColor);
			writeln();
		}
	}

	/// Turn all capabilities off.
	void restoreDefaults()
	{
		setCapability(Capability.allOff);
	}

	/// Set bold on (true) or off (false).
	@property
	void bold(in bool on)
	{
		setFace(Capability.boldFace, on);
	}

	unittest
	{
		stdout.bold = true;
		write("BOLD ");
		write("Foreground: ");
		foreach (color; __traits(allMembers, Color))
		{
			auto oldColor = stdout.foregroundColor(mixin("Color." ~ color));
			scope(exit) stdout.foregroundColor(oldColor);
			writef("%s ", color);
		}
		writeln();
		write("Background: ");
		foreach (color; __traits(allMembers, Color))
		{
			auto oldColor = stdout.backgroundColor(mixin("Color." ~ color));
			scope(exit) stdout.backgroundColor(oldColor);
			writef("%s ", color);
		}
		writeln();
		stdout.bold = false;
		write("NORMAL ");
		write("Foreground: ");
		foreach (color; __traits(allMembers, Color))
		{
			auto oldColor = stdout.foregroundColor(mixin("Color." ~ color));
			scope(exit) stdout.foregroundColor(oldColor);
			writef("%s ", color);
		}
		writeln();
		write("Background: ");
		foreach (color; __traits(allMembers, Color))
		{
			auto oldColor = stdout.backgroundColor(mixin("Color." ~ color));
			scope(exit) stdout.backgroundColor(oldColor);
			writef("%s ", color);
		}
		writeln();
	}

	/// Set blink on (true) or off (false). Note that blink on Windows
	/// intensifies the background.
	@property
	void blink(in bool on)
	{
		setFace(Capability.blinkFace, on);
	}

	unittest
	{
		stdout.blink = true;
		write("BLINK");
		stdout.blink = false;
		write(" NORMAL");
		writeln();
	}

	/// Set reverse on (true) or off (false)
	@property
	void reverse(in bool on)
	{
		setFace(Capability.reverseFace, on);
	}

	unittest
	{
		stdout.reverse = true;
		write("REVERSE");
		stdout.reverse = false;
		write(" NORMAL");
		writeln();
	}

	/// Set underline on (true) or off (false).
	/// BUGS: Does not work on Windows.
	@property
	void underline(in bool on)
	{
		setFace(Capability.underlineFace, on);
	}

	unittest
	{
		stdout.underline = true;
		write("UNDERLINE");
		stdout.underline = false;
		write(" NORMAL");
		writeln();
	}

	/// Return true if terminal refers to its output. Otherwise false.
	///
	/// TODO
	/// Checking whether the terminal is not connected to diff is recommended.
	@property
	bool isTTY() nothrow
	{
		try
		{
			return isatty(_file.fileno()) == 1;
		}
		catch (Exception)
		{
		}
		return false;
	}

	unittest
	{
		writeln(stdout.isTTY);
		writeln(stderr.isTTY);
	}

	private:
	version(Windows) WORD _startUpAttributes;
	File _file;
	alias _file this;

	void setFace(in Capability param, in bool on)
	{
		if (on) setCapability(param);
		else restoreDefaults();
	}

	version(Windows)
	{
		WORD getCharacterAttributes() const
		{
			// TODO
			// use std.stdio.stdout handle here
			// possible to use _file here?
			HANDLE stdoutHandle = GetStdHandle(STD_OUTPUT_HANDLE);
			enforce(stdoutHandle != INVALID_HANDLE_VALUE, sysErrorString(GetLastError()));
			CONSOLE_SCREEN_BUFFER_INFO consoleInfo;
			enforce(GetConsoleScreenBufferInfo(stdoutHandle, &consoleInfo), sysErrorString(GetLastError()));
			return consoleInfo.wAttributes;
		}
	}

	void setCapability(T...)(in Capability capability, in T args) if (T.length <= 1)
	{
		// TODO
		// how to set stderr?
		// setting color on stderr
		// may effect color on stdout as well if stderr is forwarded to stdout
		extern(C) static int putcharcout(int c)
		{
			return fputc(c, std.stdio.stdout.getFP);
		}
		extern(C) static int putcharcerr(int c)
		{
			return fputc(c, std.stdio.stderr.getFP);
		}

		version(Posix)
		{
			auto capabilityCString = enforce(capabilities[capability],
			                                 format("terminal does not support capability '%s'", to!string(capability)));
			// TODO
			// quick hack
			if (_file == std.stdio.stdout)
				enforce(!tputs(tparm(capabilityCString, args), 1, &putcharcout));
			else if (_file == std.stdio.stderr)
				enforce(!tputs(tparm(capabilityCString, args), 1, &putcharcerr));
			else assert(false);
		}
		else version(Windows)
		{
			// flush to make sure that all characters have been written with
			// current terminal settings
			_file.flush();
			WORD characterAttributes = getCharacterAttributes();
			final switch(capability)
			{
				case Capability.foreground:
					static assert(args.length == 1);
					characterAttributes = (characterAttributes & ~0x0007) |
					                      WindowsForegroundColor[args];
					break;
				case Capability.background:
					static assert(args.length == 1);
					characterAttributes = (characterAttributes & ~0x0070) |
					                      WindowsBackgroundColor[args];
					break;
				case Capability.boldFace:
					characterAttributes |= FOREGROUND_INTENSITY;
					break;
				case Capability.blinkFace:
					// blink on Windows is an intensified background
					characterAttributes |= BACKGROUND_INTENSITY;
					break;
				case Capability.reverseFace:
					characterAttributes |= COMMON_LVB_REVERSE_VIDEO;
					// emulating reverse
					// as it does not work on Windows for some reason
					characterAttributes = (characterAttributes & ~0x0077) |
					                      WindowsForegroundColor[backgroundColor] |
										  WindowsBackgroundColor[foregroundColor];
					break;
				case Capability.underlineFace:
					characterAttributes |= COMMON_LVB_UNDERSCORE;
					break;
				case Capability.allOff:
					characterAttributes = _startUpAttributes;
					break;
			}

			HANDLE stdoutHandle = GetStdHandle(STD_OUTPUT_HANDLE);
			enforce(SetConsoleTextAttribute(stdoutHandle, characterAttributes), sysErrorString(GetLastError()));
		}
		else static assert(0, NOT_IMPLEMENTED);
	}
}

// interface to tinfo
version(Posix)
{
version(ddl)
{
	import ddl;
	mixin declareLibraryAndAlias!("tinfo", "tinfo");
}
else
{
	import tinfo;
	// TODO
	// allow dynamic linking
	pragma(lib, "tinfo");
	pragma(lib, "termcap");
	pragma(lib, "ncurses");
}

import std.functional;
unittest
{
	class Color
	{
	}

	class NoColor
	{
	}

	// is loaded successfully
	// and has colors

	//struct O
	//{
	//	this(bool withColors)
	//	{
	//		if (withColors)
	//		{
	//		}
	//	}

	//	void write(T...)(T args)
	//	{
	//	}
	//}

	//if (hasColors)
	//{
	//	alias curry!(writecf, Color.red) inRed;
	//	alias curry!(writecf, Color.green) inGreen;
	//}
	//else
	//{
	//	alias writef inRed;
	//	alias writef inGreen;
	//}

	//inRed("In RED");
	//inGreen("In GREEN");
}

	// if loading fails fall back to no color
	// better throw an exception

	//version(ddl)
	//{
	//	// check for several libraries and load first one that exists
	//	enum libraryNames = ["tinfo", "termcap", "ncurses"];
	//	foreach (lib; libraryNames)
	//	{
	//		if (isLoadable(lib))
	//		{
	//			tinfo = loadLibrary!(tinfo)(lib, true);
	//			break;
	//		}
	//	}
	//}
}


void main()
{
}
