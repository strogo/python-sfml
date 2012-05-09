#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#
# pySFML2 - Cython SFML Wrapper for Python
# Copyright 2012, Jonathan De Wachter <dewachter.jonathan@gmail.com>
#
# This software is released under the GPLv3 license.
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


"""Python wrapper for the C++ library SFML 2 (Simple and Fast Multimedia Library)."""


import threading, subprocess, tempfile, os, time

from sfml.system.position import Position
from sfml.system.size import Size
from sfml.system.rectangle import Rectangle

from libc.stdlib cimport malloc, free
from libcpp.vector cimport vector
from cython.operator cimport preincrement as preinc, dereference as deref

from dsystem cimport Int8, Int16, Int32, Int64
from dsystem cimport Uint8, Uint16, Uint32, Uint64

cimport dsystem, dwindow

#cimport declgraphics

########################################################################
#                           System Module                              #
########################################################################

class SFMLException(Exception): pass


cdef class Time:
	cdef dsystem.Time *this

	def __cinit__(self):
		self.this = new dsystem.Time()

	def __dealloc__(self):
		del self.this

	def as_seconds(self):
		return self.this.asSeconds()

	def as_milliseconds(self):
		return self.this.asMilliseconds()

	def as_microseconds(self):
		return self.this.asMicroseconds()


cdef void sleep(Time duration):
	dsystem.sleep(duration.this[0])


cdef class Clock:
	cdef dsystem.Clock *this

	def __cinit__(self):
		self.this = new dsystem.Clock()

	def __dealloc__(self):
		del self.this

	property elapsed_time:
		def __get__(self):
			cdef dsystem.Time* p = new dsystem.Time()
			p[0] = self.this.getElapsedTime()
			return wrap_time(p)

	def restart(self):
		cdef dsystem.Time* p = new dsystem.Time()
		p[0] = self.this.restart()
		return wrap_time(p)


cdef Time wrap_time(dsystem.Time* v):
	cdef Time r = Time.__new__(Time)
	r.this = v
	return r


#cdef class Vector2f:
#    cdef declsystem.Vector2f *p_this

#    def __cinit__(self, float x=0.0, float y=0.0):
#        self.p_this = new declsystem.Vector2f(x, y)

#    def __dealloc__(self):
#        del self.p_this

#    def __repr__(self):
#        return 'Vector2f({0}, {1})'.format(self.x, self.y)

#    def __richcmp__(Vector2f a, Vector2f b, int op):
#        # ==
#        if op == 2:
#            return a.x == b.x and a.y == b.y
#        # !=
#        elif op == 3:
#            return a.x != b.x or a.y != b.y

#        return NotImplemented

#    def __add__(a, b):
#        if isinstance(a, Vector2f) and isinstance(b, Vector2f):
#            return Vector2f(a.x + b.x, a.y + b.y)

#        return NotImplemented

#    def __iadd__(self, b):
#        if isinstance(b, Vector2f):
#            self.p_this.x += b.x
#            self.p_this.y += b.y
#            return self
#        return NotImplemented

#    def __sub__(a, b):
#        if isinstance(a, Vector2f) and isinstance(b, Vector2f):
#            return Vector2f(a.x - b.x, a.y - b.y)

#    def __isub__(self, b):
#        if isinstance(b, Vector2f):
#            self.p_this.x -= b.x
#            self.p_this.y -= b.y
#            return self
#        return NotImplemented

#    def __mul__(a, b):
#        if isinstance(a, Vector2f) and isinstance(b, (int, float)):
#            return Vector2f(a.x * b, a.y * b)
#        elif isinstance(a, (int, float)) and isinstance(b, Vector2f):
#            return Vector2f(b.x * a, b.y * a)

#        return NotImplemented

#    def __imul__(self, b):
#        if isinstance(b, (int, float)):
#            self.p_this.x *= b
#            self.p_this.y *= b
#            return self
#        return NotImplemented

#    def __div__(a, b):
#        if isinstance(a, Vector2f) and isinstance(b, (int, float)):
#            return Vector2f(a.x / <float>b, a.y / <float>b)

#        return NotImplemented

#    def __idiv__(self, b):
#        if isinstance(b, (int, float)):
#            self.p_this.x /= <float>b
#            self.p_this.y /= <float>b
#            return self
#        return NotImplemented

#    def copy(self):
#        return Vector2f(self.p_this.x, self.p_this.y)

#    property x:
#        def __get__(self):
#            return self.p_this.x

#        def __set__(self, float value):
#            self.p_this.x = value

#    property y:
#        def __get__(self):
#            return self.p_this.y

#        def __set__(self, float value):
#            self.p_this.y = value

#    @classmethod
#    def from_tuple(cls, tuple t):
#        return Vector2f(t[0], t[1])


#cdef class IntRect:
#    cdef declsystem.IntRect *p_this
    
#    def __init__(self, int left=0, int top=0, int width=0, int height=0):
#        self.p_this = new declsystem.IntRect(left, top, width, height)

#    def __dealloc__(self):
#        del self.p_this

#    def __repr__(self):
#        return ('IntRect(left={0.left!r}, top={0.top!r}, '
#                'width={0.width!r}, height={0.height!r})'.format(self))

#    property left:
#        def __get__(self):
#            return self.p_this.Left

#        def __set__(self, int value):
#            self.p_this.Left = value

#    property top:
#        def __get__(self):
#            return self.p_this.Top

#        def __set__(self, int value):
#            self.p_this.Top = value

#    property width:
#        def __get__(self):
#            return self.p_this.Width

#        def __set__(self, int value):
#            self.p_this.Width = value

#    property height:
#        def __get__(self):
#            return self.p_this.Height

#        def __set__(self, int value):
#            self.p_this.Height = value

#    def contains(self, int x, int y):
#        return self.p_this.Contains(x, y)

#    def intersects(self, IntRect rect, IntRect intersection=None):
#        if intersection is None:
#            return self.p_this.Intersects(rect.p_this[0])
#        else:
#            return self.p_this.Intersects(rect.p_this[0],
#                                          intersection.p_this[0])


#cdef class FloatRect:
#    cdef declsystem.FloatRect *p_this

#    def __init__(self, float left=0, float top=0, float width=0,
#                  float height=0):
#        self.p_this = new declsystem.FloatRect(left, top, width, height)

#    def __dealloc__(self):
#        del self.p_this

#    def __repr__(self):
#        return ('FloatRect(left={0.left!r}, top={0.top!r}, '
#                'width={0.width!r}, height={0.height!r})'.format(self))

#    property left:
#        def __get__(self):
#            return self.p_this.Left

#        def __set__(self, float value):
#            self.p_this.Left = value

#    property top:
#        def __get__(self):
#            return self.p_this.Top

#        def __set__(self, float value):
#            self.p_this.Top = value

#    property width:
#        def __get__(self):
#            return self.p_this.Width

#        def __set__(self, float value):
#            self.p_this.Width = value

#    property height:
#        def __get__(self):
#            return self.p_this.Height

#        def __set__(self, float value):
#            self.p_this.Height = value

#    def contains(self, int x, int y):
#        return self.p_this.Contains(x, y)

#    def intersects(self, FloatRect rect, FloatRect intersection=None):
#        if intersection is None:
#            return self.p_this.Intersects(rect.p_this[0])
#        else:
#            return self.p_this.Intersects(rect.p_this[0], intersection.p_this[0])


#cdef declsystem.Vector2f Position_to_Vector2f(object value):
#    return declsystem.Vector2f(value[0], value[1])

#cdef declsystem.IntRect Rectangle_to_IntRect(object value):
#    return declsystem.IntRect(value[0], value[1], value[2], value[3])
    
#cdef declsystem.FloatRect Rectangle_to_FloatRect(object value):
#    x, y, w, h = value
#    return declsystem.FloatRect(float(x), float(y), float(w), float(h))

#cdef object IntRect_to_Rectangle(declsystem.IntRect* value):
#    return Rectangle(value.Left, value.Top, value.Width, value.Height)
    
#cdef object FloatRect_to_Rectangle(declsystem.FloatRect* value):
#    return Rectangle(value.Left, value.Top, value.Width, value.Height)


########################################################################
#                           Window Module                              #
########################################################################

cdef class Style:
	NONE = dwindow.style.None
	TITLEBAR = dwindow.style.Titlebar
	RESIZE = dwindow.style.Resize
	CLOSE = dwindow.style.Close
	FULLSCREEN = dwindow.style.Fullscreen
	DEFAULT = dwindow.style.Default


cdef class Event:
	CLOSED = dwindow.event.Closed
	RESIZED = dwindow.event.Resized
	LOST_FOCUS = dwindow.event.LostFocus
	GAINED_FOCUS = dwindow.event.GainedFocus
	TEXT_ENTERED = dwindow.event.TextEntered
	KEY_PRESSED = dwindow.event.KeyPressed
	KEY_RELEASED = dwindow.event.KeyReleased
	MOUSE_WHEEL_MOVED = dwindow.event.MouseWheelMoved
	MOUSE_BUTTON_PRESSED = dwindow.event.MouseButtonPressed
	MOUSE_BUTTON_RELEASED = dwindow.event.MouseButtonReleased
	MOUSE_MOVED = dwindow.event.MouseMoved
	MOUSE_ENTERED = dwindow.event.MouseEntered
	MOUSE_LEFT = dwindow.event.MouseLeft
	JOYSTICK_BUTTON_PRESSED = dwindow.event.JoystickButtonPressed
	JOYSTICK_BUTTON_RELEASED = dwindow.event.JoystickButtonReleased
	JOYSTICK_MOVED = dwindow.event.JoystickMoved
	JOYSTICK_CONNECTED = dwindow.event.JoystickConnected
	JOYSTICK_DISCONNECTED = dwindow.event.JoystickDisconnected
	COUNT = dwindow.event.Count

#    NAMES = {
#        CLOSED: 'Closed',
#        RESIZED: 'Resized',
#        LOST_FOCUS: 'Lost focus',
#        GAINED_FOCUS: 'Gained focus',
#        TEXT_ENTERED: 'Text entered',
#        KEY_PRESSED: 'Key pressed',
#        KEY_RELEASED: 'Key released',
#        MOUSE_WHEEL_MOVED: 'Mouse wheel moved',
#        MOUSE_BUTTON_PRESSED: 'Mouse button pressed',
#        MOUSE_BUTTON_RELEASED: 'Mouse button released',
#        MOUSE_MOVED: 'Mouse moved',
#        MOUSE_ENTERED: 'Mouse entered',
#        MOUSE_LEFT: 'Mouse left',
#        JOYSTICK_BUTTON_PRESSED: 'Joystick button pressed',
#        JOYSTICK_BUTTON_RELEASED: 'Joystick button released',
#        JOYSTICK_MOVED: 'Joystick moved',
#        JOYSTICK_CONNECTED: 'Joystick connected',
#        JOYSTICK_DISCONNECTED: 'Joystick disconnected'
#        }
#
#    def __str__(self):
#        """Return a short description of the event."""
#
#        return self.NAMES[self.type]



cdef class VideoMode:
	cdef dwindow.VideoMode *this
	cdef bint dthis

	def __cinit__(self, unsigned int width, unsigned int height, bpp=32):
		self.this = new dwindow.VideoMode(width, height, bpp)
		self.dthis = True

	def __dealloc__(self):
		if self.dthis:
			del self.this

	#def __str__(self):
		#return "{0.size.width}x{0.size.height}x{0.bpp}".format(self)

	#def __repr__(self):
		#return ("VideoMode({0.size.width}, {0.size.height}, {0.bpp})".format(self))

	#def __richcmp__(self, VideoMode other, int op):
		#if op == 0: # <
			#if self.bpp == other.bpp:
				#return self.size < other.size
			#else:
				#return self.bpp < other.bpp 
						   
		#elif op == 1: # <=
			#return not other < self
			
		#elif op == 2: # ==
			#return self.size == other.size and self.bpp == other.bpp        
		
		#elif op == 3: # !=
			#return self.size != other or self.bpp != other.bpp        
		
		#elif op == 4: # >
			#return other < self        
		
		#elif op == 5: # >=
			#return not self < other

	property size:
		def __get__(self):
			return Size(self.this.width, self.this.height)
			
		def __set__(self, value):
			width, height = value
			self.this.width = width
			self.this.height = height

	property bpp:
		def __get__(self):
			return self.this.bitsPerPixel

		def __set__(self, unsigned int value):
			self.this.bitsPerPixel = value

	#@classmethod
	#def get_desktop_mode(cls):
		#cdef declwindow.VideoMode *p = new declwindow.VideoMode()
		#p[0] = declwindow.videomode.GetDesktopMode()
		
		#return wrap_video_mode_instance(p, True)
		
	#@classmethod
	#def get_fullscreen_modes(cls):
		#cdef list ret = []
		#cdef vector[declwindow.VideoMode] v = declwindow.videomode.GetFullscreenModes()
		#cdef vector[declwindow.VideoMode].iterator it = v.begin()
		#cdef declwindow.VideoMode current
		#cdef declwindow.VideoMode *p_temp

		#while it != v.end():
			#current = deref(it)
			#p_temp = new declwindow.VideoMode(current.Width, current.Height, current.BitsPerPixel)
			#ret.append(wrap_video_mode_instance(p_temp, True))
			#preinc(it)

		#return ret

	def is_valid(self):
		return self.this.isValid()


#cdef VideoMode wrap_video_mode_instance(declwindow.VideoMode *p, bint delete_this):
#    cdef VideoMode ret = VideoMode.__new__(VideoMode, p.Width, p.Height, p.BitsPerPixel)
#    del ret.p_this
    
#    ret.p_this = p
#    ret.delete_this = delete_this

#    return ret


cdef class ContextSettings:
	cdef dwindow.ContextSettings *this

	def __cinit__(self, unsigned int depth=0, unsigned int stencil=0, unsigned int antialiasing=0, unsigned int major=2, unsigned int minor=0):
		self.this = new dwindow.ContextSettings(depth, stencil, antialiasing, major, minor)

	def __dealloc__(self):
		del self.this
		
	property depth_bits:
		def __get__(self):
			return self.this.depthBits

		def __set__(self, unsigned int value):
			self.this.depthBits = value

	property stencil_bits:
		def __get__(self):
			return self.this.stencilBits

		def __set__(self, unsigned int value):
			self.this.stencilBits = value

	property antialiasing_level:
		def __get__(self):
			return self.this.antialiasingLevel

		def __set__(self, unsigned int value):
			self.this.antialiasingLevel = value

	property major_version:
		def __get__(self):
			return self.this.majorVersion

		def __set__(self, unsigned int value):
			self.this.majorVersion = value

	property minor_version:
		def __get__(self):
			return self.this.minorVersion

		def __set__(self, unsigned int value):
			self.this.minorVersion = value


cdef class Window:
	cdef dwindow.Window *this

	def __cinit__(self, VideoMode mode, title, int style=Style.DEFAULT, ContextSettings settings=None):
		if self.__class__ not in [RenderWindow, HandledWindow]: # sf.RenderWindow has its own constructor 
			encoded_title = title.encode(u"ISO-8859-1")
			
			if not settings: self.this = new dwindow.Window(mode.this[0], encoded_title, style)
			else: self.this = new dwindow.Window(mode.this[0], encoded_title, style, settings.this[0])

#    def __iter__(self):
#        return self

#    def __next__(self):
#        cdef declwindow.Event p

#        if self.p_this.PollEvent(p):
#            return wrap_event_instance(&p)

#        raise StopIteration

#    property events:
#        def __get__(self):
#            return self
            
#    def create(self, VideoMode mode, title, int style=Style.DEFAULT, ContextSettings settings=None):
#        encoded_title = title.encode(u"ISO-8859-1")
#        if settings is None:
#            self.p_this.Create(mode.p_this[0], encoded_title, style)
#        else:
#            self.p_this.Create(mode.p_this[0], encoded_title, style, settings.p_this[0])


	def close(self):
		self.this.close()

	property opened:
		def __get__(self):
			return self.this.isOpen()
			
	property settings:
		def __get__(self):
			cdef dwindow.ContextSettings *p = new dwindow.ContextSettings()
			p[0] = self.this.getSettings()
			return wrap_contextsettings(p)

	def poll_event(self):
		cdef dwindow.Event *p = new dwindow.Event()

		if self.this.pollEvent(p[0]):
			return wrap_event(p)
			
	def wait_event(self):
		cdef dwindow.Event *p = new dwindow.Event()

		if self.this.waitEvent(p[0]):
			return wrap_event(p)

	property position:
		def __get__(self):
			return Position(self.this.getPosition().x, self.this.getPosition().y)

		def __set__(self, position):
			self.this.setPosition(position_to_vector2i(position))

	property size:
		def __get__(self):
			return Size(self.this.getSize().x, self.this.getSize().y)

		def __set__(self, size):
			self.this.setSize(size_to_vector2u(size))
			
	property title:
		def __set__(self, title):
			encoded_title = title.encode(u"ISO-8859-1")
			self.this.setTitle(encoded_title)
			
#    def set_icon(self, unsigned int width, unsigned int height, char* pixels):
#        self.p_this.SetIcon(width, height, <Uint8*>pixels)

	#property visible:
		#def __get__(self): pass
		#def __set__(self, visible): pass
	
	#def hide(self): pass
	#def show(self): pass

	property vertical_synchronization:
		def __set__(self, bint value):
			self.p_this.EnableVerticalSync(value)

	property mouse_cursor_visible:
		def __get__(self):
			return NotImplemented

		def __set__(self, bint mouse_cursor_visible):
			self.this.setMouseCursorVisible(mouse_cursor_visible)

	property key_repeat_enabled:
		def __get__(self):
			return NotImplemented
			
		def __set__(self, bint key_repeat_enabled):
			self.this.setKeyRepeatEnabled(key_repeat_enabled)

	property framerate_limit:
		def __get__(self):
			return NotImplemented
			
		def __set__(self, unsigned int framerate_limit):
			self.this.setFramerateLimit(framerate_limit)
			
	property joystick_threshold:
		def __get__(self):
			return NotImplemented

		def __set__(self, float joystick_threshold):
			self.this.setJoystickThreshold(joystick_threshold)

	property active:
		def __get__(self):
			return NotImplemented
			
		def __set__(self, bint active):
			self.this.setActive(active)
			
	def display(self):
		self.this.display()

	property system_handle:
		def __get__(self):
			return <unsigned long>self.this.getSystemHandle()


cdef dsystem.Vector2i position_to_vector2i(position):
	x, y = position
	return dsystem.Vector2i(x, y)

cdef dsystem.Vector2u size_to_vector2u(size):
	w, h = size
	return dsystem.Vector2u(w, h)


#cdef Window wrap_window_instance(declwindow.Window *p_cpp_instance):
#    cdef Window ret = Window.__new__(Window)
#    ret.p_this = p_cpp_instance
#    return ret

cdef class HandledWindow: pass
cdef class RenderWindow: pass

cdef class Keyboard:
	A = dwindow.keyboard.A
	B = dwindow.keyboard.B
	C = dwindow.keyboard.C
	D = dwindow.keyboard.D
	E = dwindow.keyboard.E
	F = dwindow.keyboard.F
	G = dwindow.keyboard.G
	H = dwindow.keyboard.H
	I = dwindow.keyboard.I
	J = dwindow.keyboard.J
	K = dwindow.keyboard.K
	L = dwindow.keyboard.L
	M = dwindow.keyboard.M
	N = dwindow.keyboard.N
	O = dwindow.keyboard.O
	P = dwindow.keyboard.P
	Q = dwindow.keyboard.Q
	R = dwindow.keyboard.R
	S = dwindow.keyboard.S
	T = dwindow.keyboard.T
	U = dwindow.keyboard.U
	V = dwindow.keyboard.V
	W = dwindow.keyboard.W
	X = dwindow.keyboard.X
	Y = dwindow.keyboard.Y
	Z = dwindow.keyboard.Z
	NUM0 = dwindow.keyboard.Num0
	NUM1 = dwindow.keyboard.Num1
	NUM2 = dwindow.keyboard.Num2
	NUM3 = dwindow.keyboard.Num3
	NUM4 = dwindow.keyboard.Num4
	NUM5 = dwindow.keyboard.Num5
	NUM6 = dwindow.keyboard.Num6
	NUM7 = dwindow.keyboard.Num7
	NUM8 = dwindow.keyboard.Num8
	NUM9 = dwindow.keyboard.Num9
	ESCAPE = dwindow.keyboard.Escape
	L_CONTROL = dwindow.keyboard.LControl
	L_SHIFT = dwindow.keyboard.LShift
	L_ALT = dwindow.keyboard.LAlt
	L_SYSTEM = dwindow.keyboard.LSystem
	R_CONTROL = dwindow.keyboard.RControl
	R_SHIFT = dwindow.keyboard.RShift
	R_ALT = dwindow.keyboard.RAlt
	R_SYSTEM = dwindow.keyboard.RSystem
	MENU = dwindow.keyboard.Menu
	L_BRACKET = dwindow.keyboard.LBracket
	R_BRACKET = dwindow.keyboard.RBracket
	SEMI_COLON = dwindow.keyboard.SemiColon
	COMMA = dwindow.keyboard.Comma
	PERIOD = dwindow.keyboard.Period
	QUOTE = dwindow.keyboard.Quote
	SLASH = dwindow.keyboard.Slash
	BACK_SLASH = dwindow.keyboard.BackSlash
	TILDE = dwindow.keyboard.Tilde
	EQUAL = dwindow.keyboard.Equal
	DASH = dwindow.keyboard.Dash
	SPACE = dwindow.keyboard.Space
	RETURN = dwindow.keyboard.Return
	BACK = dwindow.keyboard.Back
	TAB = dwindow.keyboard.Tab
	PAGE_UP = dwindow.keyboard.PageUp
	PAGE_DOWN = dwindow.keyboard.PageDown
	END = dwindow.keyboard.End
	HOME = dwindow.keyboard.Home
	INSERT = dwindow.keyboard.Insert
	DELETE = dwindow.keyboard.Delete
	ADD = dwindow.keyboard.Add
	SUBTRACT = dwindow.keyboard.Subtract
	MULTIPLY = dwindow.keyboard.Multiply
	DIVIDE = dwindow.keyboard.Divide
	LEFT = dwindow.keyboard.Left
	RIGHT = dwindow.keyboard.Right
	UP = dwindow.keyboard.Up
	DOWN = dwindow.keyboard.Down
	NUMPAD0 = dwindow.keyboard.Numpad0
	NUMPAD1 = dwindow.keyboard.Numpad1
	NUMPAD2 = dwindow.keyboard.Numpad2
	NUMPAD3 = dwindow.keyboard.Numpad3
	NUMPAD4 = dwindow.keyboard.Numpad4
	NUMPAD5 = dwindow.keyboard.Numpad5
	NUMPAD6 = dwindow.keyboard.Numpad6
	NUMPAD7 = dwindow.keyboard.Numpad7
	NUMPAD8 = dwindow.keyboard.Numpad8
	NUMPAD9 = dwindow.keyboard.Numpad9
	F1 = dwindow.keyboard.F1
	F2 = dwindow.keyboard.F2
	F3 = dwindow.keyboard.F3
	F4 = dwindow.keyboard.F4
	F5 = dwindow.keyboard.F5
	F6 = dwindow.keyboard.F6
	F7 = dwindow.keyboard.F7
	F8 = dwindow.keyboard.F8
	F9 = dwindow.keyboard.F9
	F10 = dwindow.keyboard.F10
	F11 = dwindow.keyboard.F11
	F12 = dwindow.keyboard.F12
	F13 = dwindow.keyboard.F13
	F14 = dwindow.keyboard.F14
	F15 = dwindow.keyboard.F15
	PAUSE = dwindow.keyboard.Pause
	KEY_COUNT = dwindow.keyboard.KeyCount

	@classmethod
	def is_key_pressed(cls, int key):
		return dwindow.keyboard.IsKeyPressed(<dwindow.keyboard.Key>key)


cdef class Joystick:
	COUNT = dwindow.joystick.Count
	BUTTON_COUNT = dwindow.joystick.ButtonCount
	AXIS_COUNT = dwindow.joystick.AxisCount

	X = dwindow.joystick.X
	Y = dwindow.joystick.Y
	Z = dwindow.joystick.Z
	R = dwindow.joystick.R
	U = dwindow.joystick.U
	V = dwindow.joystick.V
	POV_X = dwindow.joystick.PovX
	POV_Y = dwindow.joystick.PovY

	@classmethod
	def is_connected(cls, unsigned int joystick):
		return dwindow.joystick.isConnected(joystick)

	@classmethod
	def get_button_count(cls, unsigned int joystick):
		return dwindow.joystick.getButtonCount(joystick)

	@classmethod
	def has_axis(cls, unsigned int joystick, int axis):
		return dwindow.joystick.hasAxis(joystick, <dwindow.joystick.Axis>axis)

	@classmethod
	def is_button_pressed(cls, unsigned int joystick, unsigned int button):
		return dwindow.joystick.isButtonPressed(joystick, button)

	@classmethod
	def get_axis_position(cls, unsigned int joystick, int axis):
		return dwindow.joystick.getAxisPosition(joystick, <dwindow.joystick.Axis> axis)

	@classmethod
	def update(cls):
		dwindow.joystick.update()


cdef class Mouse:
	LEFT = dwindow.mouse.Left
	RIGHT = dwindow.mouse.Right
	MIDDLE = dwindow.mouse.Middle
	X_BUTTON1 = dwindow.mouse.XButton1
	X_BUTTON2 = dwindow.mouse.XButton2
	BUTTON_COUNT = dwindow.mouse.ButtonCount

	@classmethod
	def is_button_pressed(cls, int button):
		return dwindow.mouse.isButtonPressed(<dwindow.mouse.Button>button)

	@classmethod
	def get_position(cls, Window window=None):
		cdef dsystem.Vector2i p

		if window is None: p = dwindow.mouse.getPosition()
		else: p = dwindow.mouse.getPosition(window.this[0])

		return Position(p.x, p.y)

	@classmethod
	def set_position(cls, position, Window window=None):
		cdef dsystem.Vector2i p
		p.x, p.y = position

		if window is None: dwindow.mouse.setPosition(p)
		else: dwindow.mouse.setPosition(p, window.this[0])


# Create an Python Event object that matches the C++ object
# by dynamically setting the corresponding attributes.
cdef wrap_event(dwindow.Event *cpp_event):
	cdef Event event = Event.__new__(Event)
	cdef Uint32 code
		
	event.type = <int>cpp_event.Type

	# Set other attributes if needed
	if cpp_event.Type == dwindow.event.Resized:
		event.width = cpp_event.size.width
		event.height = cpp_event.size.height
		
	elif cpp_event.Type == dwindow.event.TextEntered:
		code = cpp_event.text.unicode
		event.unicode = ((<char*>&code)[:4]).decode('utf-32-le')
		
	elif cpp_event.Type == dwindow.event.KeyPressed or cpp_event.Type == dwindow.event.KeyReleased:
		event.code = cpp_event.key.code
		event.alt = cpp_event.key.alt
		event.control = cpp_event.key.control
		event.shift = cpp_event.key.shift
		event.system = cpp_event.key.system
		
	elif cpp_event.Type == dwindow.event.MouseButtonPressed or cpp_event.Type == dwindow.event.MouseButtonReleased:
		event.button = cpp_event.mouseButton.button
		event.position = Position(cpp_event.mouseButton.x, cpp_event.mouseButton.y)

	elif cpp_event.Type == dwindow.event.MouseMoved:
		event.position = Position(cpp_event.mouseMove.x, cpp_event.mouseMove.y)
		
	elif cpp_event.Type == dwindow.event.MouseWheelMoved:
		event.delta = cpp_event.mouseWheel.delta
		event.position = Position(cpp_event.mouseWheel.x, cpp_event.mouseWheel.y)
		
	elif cpp_event.Type == dwindow.event.JoystickButtonPressed or cpp_event.Type == dwindow.event.JoystickButtonReleased:
		event.joystick_id = cpp_event.joystickButton.joystickId
		event.button = cpp_event.joystickButton.button
		
	elif cpp_event.Type == dwindow.event.JoystickMoved:
		event.joystick_id = cpp_event.joystickMove.joystickId
		event.axis = cpp_event.joystickMove.axis
		event.position = cpp_event.joystickMove.position
		
	elif cpp_event.Type == dwindow.event.JoystickConnected or  cpp_event.Type == dwindow.event.JoystickDisconnected:
		event.joystick_id = cpp_event.joystickConnect.joystickId

	return event

cdef ContextSettings wrap_contextsettings(dwindow.ContextSettings *v):
	cdef ContextSettings r = ContextSettings.__new__(ContextSettings)
	r.this = v
	return r


#########################################################################
##                           Graphics Module                            #
#########################################################################

#cdef class BlendMode:
#    ALPHA = declgraphics.blendmode.Alpha
#    ADD = declgraphics.blendmode.Add
#    MULTIPLY = declgraphics.blendmode.Multiply
#    NONE = declgraphics.blendmode.None


#cdef class Matrix3:
#    cdef declgraphics.Matrix3 *p_this

#    IDENTITY = wrap_matrix_instance(<declgraphics.Matrix3*>&declgraphics.matrix3.Identity)

#    def __init__(self, float a00, float a01, float a02,
#                  float a10, float a11, float a12,
#                  float a20, float a21, float a22):
#        self.p_this = new declgraphics.Matrix3(a00, a01, a02,
#                                       a10, a11, a12,
#                                       a20, a21, a22)

#    def __dealloc__(self):
#        del self.p_this

#    def __str__(self):
#        cdef float *p

#        p = <float*>self.p_this.Get4x4Elements()

#        return ('[{0} {4} {8} {12}]\n'
#                '[{1} {5} {9} {13}]\n'
#                '[{2} {6} {10} {14}]\n'
#                '[{3} {7} {11} {15}]'
#                .format(p[0], p[1], p[2], p[3],
#                        p[4], p[5], p[6], p[7],
#                        p[8], p[9], p[10], p[11],
#                        p[12], p[13], p[14], p[15]))

#    def __mul__(Matrix3 self, Matrix3 other):
#        cdef declgraphics.Matrix3 *p = new declgraphics.Matrix3()

#        p[0] = self.p_this[0] * other.p_this[0]

#        return wrap_matrix_instance(p)

#    @classmethod
#    def projection(cls, center, size, float rotation):
#        cdef declgraphics.Vector2f cpp_center = Position_to_Vector2f(center)
#        cdef declgraphics.Vector2f cpp_size = Position_to_Vector2f(size)
#        cdef declgraphics.Matrix3 *p = new declgraphics.Matrix3()

#        p[0] = declgraphics.matrix3.Projection(cpp_center, cpp_size, rotation)

#        return wrap_matrix_instance(p)
        
#    @classmethod
#    def transformation(cls, origin, translation, float rotation, scale):
#        cdef declgraphics.Vector2f cpp_origin = Position_to_Vector2f(origin)
#        cdef declgraphics.Vector2f cpp_translation = Position_to_Vector2f(translation)
#        cdef declgraphics.Vector2f cpp_scale = Position_to_Vector2f(scale)
#        cdef declgraphics.Matrix3 *p = new declgraphics.Matrix3()

#        p[0] = declgraphics.matrix3.Transformation(cpp_origin, cpp_translation, rotation, cpp_scale)

#        return wrap_matrix_instance(p)

#    def get_inverse(self):
#        cdef declgraphics.Matrix3 m = self.p_this.GetInverse()
#        cdef declgraphics.Matrix3 *p = new declgraphics.Matrix3()

#        p[0] = m

#        return wrap_matrix_instance(p)

#    def transform(self, point):
#        cdef declgraphics.Vector2f cpp_point = Position_to_Vector2f(point)
#        cdef declgraphics.Vector2f res

#        res = self.p_this.Transform(cpp_point)

#        return (res.x, res.y)


#cdef Matrix3 wrap_matrix_instance(declgraphics.Matrix3 *p_cpp_instance):
#    cdef Matrix3 ret = Matrix3.__new__(Matrix3)

#    ret.p_this = p_cpp_instance

#    return ret


#cdef class Color:
#    BLACK = Color(0, 0, 0)
#    WHITE = Color(255, 255, 255)
#    RED = Color(255, 0, 0)
#    GREEN = Color(0, 255, 0)
#    BLUE = Color(0, 0, 255)
#    YELLOW = Color(255, 255, 0)
#    MAGENTA = Color(255, 0, 255)
#    CYAN = Color(0, 255, 255)

#    cdef declgraphics.Color *p_this

#    def __init__(self, int r, int g, int b, int a=255):
#        self.p_this = new declgraphics.Color(r, g, b, a)

#    def __dealloc__(self):
#        del self.p_this

#    def __repr__(self):
#        return 'Color({0.r}, {0.g}, {0.b}, {0.a})'.format(self)

#    def __richcmp__(Color x, Color y, int op):
#        # ==
#        if op == 2:
#            return (x.r == y.r and
#                    x.g == y.g and
#                    x.b == y.b and
#                    x.a == y.a)
#        # !=
#        elif op == 3:
#            return not x == y

#        return NotImplemented

#    def __add__(Color x, Color y):
#        return Color(min(x.r + y.r, 255),
#                     min(x.g + y.g, 255),
#                     min(x.b + y.b, 255),
#                     min(x.a + y.a, 255))

#    def __mul__(Color x, Color y):
#        return Color(x.r * y.r / 255,
#                     x.g * y.g / 255,
#                     x.b * y.b / 255,
#                     x.a * y.a / 255)

#    property r:
#        def __get__(self):
#            return self.p_this.r

#        def __set__(self, unsigned int value):
#            self.p_this.r = value

#    property g:
#        def __get__(self):
#            return self.p_this.g

#        def __set__(self, unsigned int value):
#            self.p_this.g = value

#    property b:
#        def __get__(self):
#            return self.p_this.b

#        def __set__(self, unsigned int value):
#            self.p_this.b = value

#    property a:
#        def __get__(self):
#            return self.p_this.a

#        def __set__(self, unsigned int value):
#            self.p_this.a = value


#cdef wrap_color_instance(declgraphics.Color *p_cpp_instance):
#    cdef Color ret = Color.__new__(Color)
#    ret.p_this = p_cpp_instance

#    return ret


#cdef class Glyph:
#    cdef declgraphics.Glyph *p_this

#    def __init__(self):
#        self.p_this = new declgraphics.Glyph()

#    def __dealloc__(self):
#        del self.p_this

#    property advance:
#        def __get__(self):
#            return self.p_this.Advance

#    property bounds:
#        def __get__(self):
#            return <object>IntRect_to_Rectangle(&self.p_this.Bounds)


#    property sub_rect:
#        def __get__(self):
#            #not efficient
#            return <object>IntRect_to_Rectangle(&self.p_this.SubRect)
            
#            #cdef declgraphics.IntRect *p = new declgraphics.IntRect()
#            #p[0] = self.p_this.SubRect
#            #return wrap_int_rect_instance(p)
            


#cdef Glyph wrap_glyph_instance(declgraphics.Glyph *p_cpp_instance):
#    cdef Glyph ret = Glyph.__new__(Glyph)

#    ret.p_this = p_cpp_instance

#    return ret


#cdef class Font:
#    cdef declgraphics.Font *p_this
#    cdef bint delete_this

#    DEFAULT_FONT = wrap_font_instance(<declgraphics.Font*>&declgraphics.font.GetDefaultFont(), False)

#    def __init__(self):
#        self.p_this = new declgraphics.Font()
#        self.delete_this = True

#    def __dealloc__(self):
#        if self.delete_this:
#            del self.p_this

#    @classmethod
#    def load_from_file(cls, filename):
#        cdef declgraphics.Font *p = new declgraphics.Font()

#        bFilename = filename.encode('UTF-8')
#        if p.LoadFromFile(bFilename):
#            return wrap_font_instance(p, True)

#        raise SFMLException()

#    @classmethod
#    def load_from_memory(cls, bytes data):
#        cdef declgraphics.Font *p = new declgraphics.Font()

#        if p.LoadFromMemory(<char*>data, len(data)):
#            return wrap_font_instance(p, True)

#        raise SFMLException()

#    def get_glyph(self, unsigned int code_point, unsigned int character_size,
#                  bint bold):
#        cdef declgraphics.Glyph *p = new declgraphics.Glyph()

#        p[0] = self.p_this.GetGlyph(code_point, character_size, bold)

#        return wrap_glyph_instance(p)

#    def get_texture(self, unsigned int character_size):
#        cdef declgraphics.Texture *p = <declgraphics.Texture*>&self.p_this.GetTexture(
#            character_size)

#        return wrap_texture_instance(p, False)

#    def get_kerning(self, unsigned int first, unsigned int second,
#                    unsigned int character_size):
#        return self.p_this.GetKerning(first, second, character_size)

#    def get_line_spacing(self, unsigned int character_size):
#        return self.p_this.GetLineSpacing(character_size)


#cdef Font wrap_font_instance(declgraphics.Font *p_cpp_instance, bint delete_this):
#    cdef Font ret = Font.__new__(Font)

#    ret.p_this = p_cpp_instance
#    ret.delete_this = delete_this

#    return ret


#cdef class Image:
#    cdef declgraphics.Image *p_this
#    cdef bint delete_this

#    def __init__(self, int width, int height, Color color=None):
#        self.p_this = new declgraphics.Image()
#        self.delete_this = True

#        if color is None:
#            self.p_this.Create(width, height)
#        else:
#            self.p_this.Create(width, height, color.p_this[0])

#    def __dealloc__(self):
#        if self.delete_this:
#            del self.p_this

#    def __getitem__(self, tuple key):
#        return self.get_pixel(key[0], key[1])

#    def __setitem__(self, tuple key, Color value):
#        self.set_pixel(key[0], key[1], value)

#    property size:
#        def __get__(self):
#            return Size(self.width, self.height)

#    property width:
#        def __get__(self):
#            return self.p_this.GetWidth()
            
#    property height:
#        def __get__(self):
#            return self.p_this.GetHeight()

#    @classmethod
#    def load_from_file(cls, filename):
#        cdef declgraphics.Image *p_cpp_instance = new declgraphics.Image()

#        encoded_filename = filename.encode('UTF-8')
#        if p_cpp_instance.LoadFromFile(encoded_filename):
#            return wrap_image_instance(p_cpp_instance, True)

#        raise SFMLException()

#    @classmethod
#    def load_from_memory(cls, bytes data):
#        cdef declgraphics.Image *p_cpp_instance = new declgraphics.Image()
        
#        if p_cpp_instance.LoadFromMemory(<char*>data, len(data)):
#            return wrap_image_instance(p_cpp_instance, True)

#        raise SFMLException()

#    # TODO: maybe this should be moved to the constructor, since the method
#    # was renamed from LoadFromPixels() to Create()
#    @classmethod
#    def load_from_pixels(cls, int width, int height, char *pixels):
#        cdef declgraphics.Image *p_cpp_instance = new declgraphics.Image()

#        p_cpp_instance.Create(width, height, <unsigned char*>pixels)

#        return wrap_image_instance(p_cpp_instance, True)

#    def copy(self, Image source, object destination, object rect=None, bint apply_alpha=False):
#        cdef declgraphics.IntRect cpp_rect
#        x, y = destination
        
#        if rect is None:
#            self.p_this.Copy(source.p_this[0], x, y)
#        else:
#            cpp_rect = Rectangle_to_IntRect(rect)
#            self.p_this.Copy(source.p_this[0], x, y, cpp_rect, apply_alpha)

#    def create_mask_from_color(self, Color color, int alpha=0):
#        self.p_this.CreateMaskFromColor(color.p_this[0], alpha)
        
#    def set_pixel(self, int x, int y, Color color):
#        self.p_this.SetPixel(x, y, color.p_this[0])
        
#    def get_pixel(self, int x, int y):
#        cdef declgraphics.Color *p_color = new declgraphics.Color()
#        cdef declgraphics.Color temp = self.p_this.GetPixel(x, y)

#        p_color[0] = temp

#        return wrap_color_instance(p_color)

#    def get_pixels(self):
#        """Return a string containing the pixels of the image in RGBA fomat."""

#        cdef char* p = <char*>self.p_this.GetPixelsPtr()
#        cdef int length = self.width * self.height * 4
#        cdef bytes ret = p[:length]

#        return ret

#    def save_to_file(self, filename):
#        filenameb = filename.encode('UTF-8')
#        if self.p_this.SaveToFile(<char*>filenameb) is False:
#            print("Image::save_to_filed has failed!")
#            raise SFMLException()

#    def show(self):
#        image_filename = "/tmp/sfml.png"
#        script_filename = os.path.dirname(__file__) + "/show.py"
#        try:
#            self.save_to_file(image_filename)
#        except SFMLException:
#            print("Image::show() -> Couln't create a temporary image")
#            return

#        subprocess.Popen(['/usr/bin/python3', script_filename, image_filename])
#        time.sleep(0.150)     
        
#cdef Image wrap_image_instance(declgraphics.Image *p_cpp_instance, bint delete_this):
#    cdef Image ret = Image.__new__(Image)
#    ret.p_this = p_cpp_instance
#    ret.delete_this = delete_this

#    return ret


#cdef class Texture:
#    cdef declgraphics.Texture *p_this
#    cdef bint delete_this

#    MAXIMUM_SIZE = declgraphics.texture.GetMaximumSize()

#    def __init__(self, unsigned int width=0, unsigned int height=0):
#        self.p_this = new declgraphics.Texture()
#        self.delete_this = True

#        if width > 0 and height > 0:
#            if self.p_this.Create(width, height) != True:
#                raise SFMLException()

#    def __dealloc__(self):
#        if self.delete_this:
#            del self.p_this

#    property width:
#        def __get__(self):
#            return self.p_this.GetWidth()
            
#    property height:
#        def __get__(self):
#            return self.p_this.GetHeight()

#    property size:
#        def __get__(self):
#            return Size(self.width, self.height)

#    property smooth:
#        def __get__(self):
#            return self.p_this.IsSmooth()

#        def __set__(self, bint value):
#            self.p_this.SetSmooth(value)

#    @classmethod
#    def load_from_file(cls, filename, object area=None):
#        cdef declgraphics.Texture *p_cpp_instance = new declgraphics.Texture()
        
#        encoded_filename = filename.encode('UTF-8')
        
#        if area is None:
#            if p_cpp_instance.LoadFromFile(encoded_filename):
#                return wrap_texture_instance(p_cpp_instance, True)
#        else:
#            if p_cpp_instance.LoadFromFile(encoded_filename, Rectangle_to_IntRect(area)):
#                return wrap_texture_instance(p_cpp_instance, True)

#        raise SFMLException()

#    @classmethod
#    def load_from_image(cls, Image image, object area=None):
#        cdef declgraphics.Texture *p_cpp_instance = new declgraphics.Texture()

#        if area is None:
#            if p_cpp_instance.LoadFromImage(image.p_this[0]):
#                return wrap_texture_instance(p_cpp_instance, True)
#        else:
#            if p_cpp_instance.LoadFromImage(image.p_this[0], Rectangle_to_IntRect(area)):
#                return wrap_texture_instance(p_cpp_instance, True)

#        raise SFMLException()

#    @classmethod
#    def load_from_memory(cls, bytes data, area=None):
#        cdef declgraphics.Texture *p_cpp_instance = new declgraphics.Texture()

#        if area is None:
#            if p_cpp_instance.LoadFromMemory(<char*>data, len(data)):
#                return wrap_texture_instance(p_cpp_instance, True)
#        else:
#            if p_cpp_instance.LoadFromMemory(<char*>data, len(data), Rectangle_to_IntRect(area)):
#                return wrap_texture_instance(p_cpp_instance, True)

#        raise SFMLException()

#    def bind(self):
#        self.p_this.Bind()

#    def get_tex_coords(self, rect):
#        cdef declsystem.IntRect cpp_rect = Rectangle_to_IntRect(rect)
#        cdef declsystem.FloatRect res = self.p_this.GetTexCoords(cpp_rect)
#        cdef declsystem.FloatRect *p = new declgraphics.FloatRect()

#        p[0] = res

#        return FloatRect_to_Rectangle(p)

#    def update(self, object source, int p1=-1, int p2=-1, int p3=-1, int p4=-1):
#        if isinstance(source, bytes):
#            if p1 == -1:
#                self.p_this.Update(<declgraphics.Uint8*>(<char*>source))
#            else:
#                self.p_this.Update(<declgraphics.Uint8*>(<char*>source),
#                                   p1, p2, p3, p4)
#        elif isinstance(source, Image):
#            if p1 == -1:
#                self.p_this.Update((<Image>source).p_this[0])
#            else:
#                self.p_this.Update((<Image>source).p_this[0], p1, p2)
#        elif isinstance(source, Window):
#            if p1 == -1:
#                self.p_this.Update((<declwindow.Window*>(<Window>source).p_this)[0])
#            else:
#                self.p_this.Update((<declwindow.Window*>(<Window>source).p_this)[0], p1, p2)
#        else:
#            raise TypeError(
#                "The source argument should be of type str / bytes(py3k), "
#                "Image or RenderWindow (found {0})".format(type(source)))


#cdef Texture wrap_texture_instance(declgraphics.Texture *p_cpp_instance,
#                                   bint delete_this):
#    cdef Texture ret = Texture.__new__(Texture)
#    ret.p_this = p_cpp_instance
#    ret.delete_this = delete_this

#    return ret
    

#cdef class Drawable:
#    cdef declgraphics.Drawable *p_this

#    def __cinit__(self, *args, **kwargs):
#        if self.__class__ == Drawable:
#            raise NotImplementedError('Drawable is abstact')
#        elif self.__class__ not in [Shape, Sprite, Text]:
#            # custom drawable instantiated
#            self.p_this = <declgraphics.Drawable*>new declgraphics.PyDrawable(<void*>self)
        
#    property blend_mode:
#        def __get__(self):
#            return <int>self.p_this.GetBlendMode()

#        def __set__(self, int value):
#            self.p_this.SetBlendMode(<declgraphics.blendmode.Mode>value)

#    property color:
#        def __get__(self):
#            cdef declgraphics.Color *p = new declgraphics.Color()

#            p[0] = self.p_this.GetColor()

#            return wrap_color_instance(p)

#        def __set__(self, Color value):
#            self.p_this.SetColor(value.p_this[0])

#    property origin:
#        def __get__(self):
#            cdef declgraphics.Vector2f origin = self.p_this.GetOrigin()

#            return (origin.x, origin.y)

#        def __set__(self, value):
#            cdef declgraphics.Vector2f v = Position_to_Vector2f(value)

#            self.p_this.SetOrigin(v.x, v.y)

#    property position:
#        def __get__(self):
#            return Position(self.p_this.GetPosition().x, self.p_this.GetPosition().y)

#        def __set__(self, value):
#            self.p_this.SetPosition(Position_to_Vector2f(value))
            
#    property rotation:
#        def __get__(self):
#            return self.p_this.GetRotation()

#        def __set__(self, float value):
#            self.p_this.SetRotation(value)

#    property scale:
#        def __get__(self):
#            cdef declgraphics.Vector2f scale = self.p_this.GetScale()

#            return ScaleWrapper(self, scale.x, scale.y)

#        def __set__(self, value):
#            cdef declgraphics.Vector2f v = Position_to_Vector2f(value)

#            self.p_this.SetScale(v.x, v.y)

#    property x:
#        def __get__(self):
#            return self.position.x

#        def __set__(self, float value):
#            self.p_this.SetX(value)

#    property y:
#        def __get__(self):
#            return self.position.y

#        def __set__(self, float value):
#            self.p_this.SetY(value)

#    def render(self, target, renderer):
#        raise NotImplementedError("You must override this method!")
        
#    def transform_to_local(self, float x, float y):
#        cdef declgraphics.Vector2f cpp_point
#        cdef declgraphics.Vector2f res

#        cpp_point.x = x
#        cpp_point.y = y
#        res = self.p_this.TransformToLocal(cpp_point)

#        return (res.x, res.y)

#    def transform_to_global(self, float x, float y):
#        cdef declgraphics.Vector2f cpp_point
#        cdef declgraphics.Vector2f res

#        cpp_point.x = x
#        cpp_point.y = y
#        res = self.p_this.TransformToGlobal(cpp_point)

#        return (res.x, res.y)

#    def move(self, float x, float y):
#        self.p_this.Move(x, y)

#    def rotate(self, float angle):
#        self.p_this.Rotate(angle)

#    def _scale(self, float x, float y):
#        self.p_this.Scale(x, y)


## This class allows the user to use the Drawable.scale attribute both
## for GetScale()/SetScale() property and the Scale() method.  When the
## user calls the getter for Drawable.scale, the object returned is an
## instance of this class. It will behave like a tuple, except that the
## call overrides __call__() so that the C++ Scale() method is called
## when the user types some_drawable.scale().
#class ScaleWrapper(tuple):
#    def __new__(cls, Drawable drawable, float x, float y):
#        return tuple.__new__(cls, (x, y))

#    def __init__(self, Drawable drawable, float x, float y):
#        self.drawable = drawable

#    def __call__(self, float x, float y):
#        self.drawable._scale(x, y)


#cdef class Text(Drawable):
#    cdef bint is_unicode

#    REGULAR = declgraphics.text.Regular
#    BOLD = declgraphics.text.Bold
#    ITALIC = declgraphics.text.Italic
#    UNDERLINED = declgraphics.text.Underlined

#    def __cinit__(self, string=None, Font font=None, int character_size=0):
#        cdef declsystem.String cpp_string
#        cdef char* c_string = NULL

#        self.is_unicode = False

#        if string is None:
#            self.p_this = <declgraphics.Drawable*>new declgraphics.Text()
#        elif isinstance(string, bytes):
#            if font is None:
#                self.p_this = <declgraphics.Drawable*>new declgraphics.Text(<char*>string)
#            elif character_size == 0:
#                self.p_this = <declgraphics.Drawable*>new declgraphics.Text(
#                    <char*>string, font.p_this[0])
#            else:
#                self.p_this = <declgraphics.Drawable*>new declgraphics.Text(
#                    <char*>string, font.p_this[0], character_size)
#        elif isinstance(string, unicode):
#            self.is_unicode = True
#            string += '\x00'
#            py_byte_string = string.encode('utf-32-le')
#            c_string = py_byte_string
#            cpp_string = declsystem.String(<declgraphics.Uint32*>c_string)

#            if font is None:
#                self.p_this = <declgraphics.Drawable*>new declgraphics.Text(cpp_string)
#            elif character_size == 0:
#                self.p_this = <declgraphics.Drawable*>new declgraphics.Text(
#                    cpp_string, font.p_this[0])
#            else:
#                self.p_this = <declgraphics.Drawable*>new declgraphics.Text(
#                    cpp_string, font.p_this[0], character_size)
#        else:
#            raise TypeError("Expected bytes/str or unicode for string, got {0}"
#                            .format(type(string)))

#    def __dealloc__(self):
#        del self.p_this

#    property character_size:
#        def __get__(self):
#            return (<declgraphics.Text*>self.p_this).GetCharacterSize()

#        def __set__(self, int value):
#            (<declgraphics.Text*>self.p_this).SetCharacterSize(value)

#    property font:
#        def __get__(self):
#            cdef declgraphics.Font *p = <declgraphics.Font*>&(<declgraphics.Text*>self.p_this).GetFont()

#            return wrap_font_instance(p, False)

#        def __set__(self, Font value):
#            (<declgraphics.Text*>self.p_this).SetFont(value.p_this[0])

#    property rect:
#        def __get__(self):
#            cdef declgraphics.FloatRect *p = new declgraphics.FloatRect()
#            p[0] = (<declgraphics.Text*>self.p_this).GetRect()
#            return FloatRect_to_Rectangle(p)

#    property string:
#        def __get__(self):
#            cdef declgraphics.string res
#            cdef char *p = NULL
#            cdef bytes data

#            if not self.is_unicode:
#                res = ((<declgraphics.Text*>self.p_this).GetString()
#                       .ToAnsiString())
#                ret = res.c_str()
#            else:
#                p = <char*>(<declgraphics.Text*>self.p_this).GetString().GetData()
#                data = p[:(<declgraphics.Text*>self.p_this).GetString().GetSize() * 4]
#                ret = data.decode('utf-32-le')

#            return ret

#        def __set__(self, value):
#            cdef char* c_string = NULL

#            if isinstance(value, bytes):
#                (<declgraphics.Text*>self.p_this).SetString(<char*>value)
#                self.is_unicode = False
#            elif isinstance(value, unicode):
#                value += '\x00'
#                py_byte_string = value.encode('utf-32-le')
#                c_string = py_byte_string
#                (<declgraphics.Text*>self.p_this).SetString(
#                    declsystem.String(<declgraphics.Uint32*>c_string))
#                self.is_unicode = True
#            else:
#                raise TypeError(
#                    "Expected bytes/str or unicode for string, got {0}"
#                    .format(type(value)))

#    property style:
#        def __get__(self):
#            return (<declgraphics.Text*>self.p_this).GetStyle()

#        def __set__(self, int value):
#            (<declgraphics.Text*>self.p_this).SetStyle(value)

#    def get_character_pos(self, int index):
#        cdef declgraphics.Vector2f res = (<declgraphics.Text*>self.p_this).GetCharacterPos(
#            index)

#        return (res.x, res.y)


#cdef class Sprite(Drawable):
#    cdef Texture texture

#    def __cinit__(self, Texture texture=None):
#        if texture is None:
#            self.texture = None
#            self.p_this = <declgraphics.Drawable*>new declgraphics.Sprite()
#        else:
#            self.texture = texture
#            self.p_this = <declgraphics.Drawable*>new declgraphics.Sprite(texture.p_this[0])

#    def __dealloc__(self):
#        del self.p_this

#    def __getitem__(self, coords):
#        cdef declgraphics.Vector2f v = Position_to_Vector2f(coords)

#        return self.get_pixel(v.x, v.y)

#    property height:
#        def __get__(self):
#            return (<declgraphics.Sprite*>self.p_this).GetSize().y

#    property size:
#        def __get__(self):
#            return (self.width, self.height)

#    property texture:
#        def __get__(self):
#            return self.texture

#        def __set__(self, Texture value):
#            self.texture = value
#            (<declgraphics.Sprite*>self.p_this).SetTexture(value.p_this[0])

#    property width:
#        def __get__(self):
#            return (<declgraphics.Sprite*>self.p_this).GetSize().x

#    def get_sub_rect(self):
#        cdef declgraphics.IntRect r = (<declgraphics.Sprite*>self.p_this).GetSubRect()

#        return IntRect(r.Left, r.Top, r.Width, r.Height)

#    def flip_x(self, bint flipped):
#        (<declgraphics.Sprite*>self.p_this).FlipX(flipped)

#    def flip_y(self, bint flipped):
#        (<declgraphics.Sprite*>self.p_this).FlipY(flipped)

#    def resize(self, float width, float height):
#        (<declgraphics.Sprite*>self.p_this).Resize(width, height)

#    def set_sub_rect(self, object rect):
#        cdef declgraphics.IntRect r = Rectangle_to_IntRect(rect)

#        (<declgraphics.Sprite*>self.p_this).SetSubRect(r)

#    def set_texture(self, Texture texture, bint adjust_to_new_size=False):
#        self.texture = texture
#        (<declgraphics.Sprite*>self.p_this).SetTexture(texture.p_this[0], adjust_to_new_size)


#cdef class Shape
#cdef class Point:
#    cdef declgraphics.Shape* tshape
#    cdef unsigned int pindex
    
#    def __cinit__(self, Shape tshape, unsigned int pindex):
#        self.tshape = <declgraphics.Shape*>tshape.p_this
#        self.pindex = pindex
        
#    property position:
#        def __get__(self):
#            cdef declgraphics.Vector2f pos
#            pos = self.tshape.GetPointPosition(self.pindex)
#            return Position(pos.x, pos.y)
            
#        def __set__(self, object position):
#            x, y = position
#            self.tshape.SetPointPosition(self.pindex, x, y)
            
#    property color:
#        def __get__(self):
#            cdef declgraphics.Color *p = new declgraphics.Color()
#            p[0] = self.tshape.GetPointColor(self.pindex)
#            return wrap_color_instance(p)

#        def __set__(self, Color color):
#            self.tshape.SetPointColor(self.pindex, color.p_this[0])
            
#    property outline_color:
#        def __get__(self):
#            cdef declgraphics.Color *p = new declgraphics.Color()
#            p[0] = self.tshape.GetPointOutlineColor(self.pindex)
#            return wrap_color_instance(p)
                       
#        def __set__(self, Color color):
#            self.tshape.SetPointOutlineColor(self.pindex, color.p_this[0])
    

#cdef class Shape(Drawable):
#    cdef object _points
#    cdef bint _fill_enabled
#    cdef bint _outline_enabled
    
#    def __cinit__(self):
#        self.p_this = <declgraphics.Drawable*>new declgraphics.Shape()
#        self._points = []   
             
#    def __init__(self):
#        self._fill_enabled = True
#        self._outline_enabled = True
        
#    def __dealloc__(self):
#        del self.p_this
    
#    property fill_enabled:
#        def __get__(self):
#            return self._fill_enabled
            
#        def __set__(self, bint value):
#            (<declgraphics.Shape*>self.p_this).EnableFill(value)
#            self._fill_enabled = value

#    property outline_enabled:
#        def __get__(self):
#            return self._outline_enabled
            
#        def __set__(self, bint value):
#            (<declgraphics.Shape*>self.p_this).EnableOutline(value)
#            self._outline_enabled = value
            
#    property outline_thickness:
#        def __get__(self):
#            return (<declgraphics.Shape*>self.p_this).GetOutlineThickness()

#        def __set__(self, float value):
#            (<declgraphics.Shape*>self.p_this).SetOutlineThickness(value)

#    property points:
#        def __get__(self):
#            return self._points

#    @classmethod
#    def line(cls, object start, object end, float thickness, Color color, float outline=0.0, Color outline_color=None):
#        cdef declgraphics.Shape *p = new declgraphics.Shape()
#        p1x, p1y = start
#        p2x, p2y = end

#        if outline_color is None:
#            p[0] = declgraphics.shape.Line(<float>p1x, <float>p1y, <float>p2x, <float>p2y, thickness, color.p_this[0], outline)
#        else:
#            p[0] = declgraphics.shape.Line(<float>p1x, <float>p1y, <float>p2x, <float>p2y, thickness, color.p_this[0], outline, outline_color.p_this[0])

#        return wrap_shape_instance(p)

#    @classmethod
#    def rectangle(cls, object rect, Color color, float outline=0.0, Color outline_color=None):
#        cdef declgraphics.Shape *p = new declgraphics.Shape()
#        left, top, width, height = rect
        
#        if outline_color is None:
#            p[0] = declgraphics.shape.Rectangle(<float>left, <float>top, <float>width, <float>height, color.p_this[0], outline)
#        else:
#            p[0] = declgraphics.shape.Rectangle(<float>left, <float>top, <float>width, <float>height, color.p_this[0], outline, outline_color.p_this[0])

#        return wrap_shape_instance(p)

#    @classmethod
#    def circle(cls, object center, float radius, Color color, float outline=0.0, Color outline_color=None):
#        cdef declgraphics.Shape *p = new declgraphics.Shape()
#        x, y = center
        
#        if outline_color is None:
#            p[0] = declgraphics.shape.Circle(<float>x, <float>y, radius, color.p_this[0], outline)
#        else:
#            p[0] = declgraphics.shape.Circle(<float>x, <float>y, radius, color.p_this[0], outline, outline_color.p_this[0])

#        return wrap_shape_instance(p)

#    def add_point(self, object position, Color color=None, Color outline_color=None):
#        x, y = position
        
#        self._points.append(Point(self, (<declgraphics.Shape*>self.p_this).GetPointsCount()))
        
#        if color is None:
#            (<declgraphics.Shape*>self.p_this).AddPoint(<float>x, <float>y)
#        elif outline_color is None:
#            (<declgraphics.Shape*>self.p_this).AddPoint(<float>x, <float>y, color.p_this[0])
#        else:
#            (<declgraphics.Shape*>self.p_this).AddPoint(<float>x, <float>y, color.p_this[0], outline_color.p_this[0])



#cdef Shape wrap_shape_instance(declgraphics.Shape *p):
#    cdef Shape ret = Shape.__new__(Shape)
#    ret.p_this = <declgraphics.Drawable*>p
    
#    for i in range(p.GetPointsCount()):
#        ret.points.append(Point(ret, i))
        
    
#    return ret

#cdef class View:
#    cdef declgraphics.View *p_this
#    # A RenderTarget (e.g., a RenderWindow or a RenderTexture) can be
#    # bound to the view. Every time the view is changed, the target
#    # will be automatically updated. The target object must have a
#    # view property.  This is used so that code like
#    # declwindow.view.move(10, 10) works as expected.
#    cdef object render_target
#    cdef object _size
    
#    def __init__(self):
#        self.p_this = new declgraphics.View()
#        self.render_target = None

#        #self._size = Size()
#        #self._size._set_height = method1
#        #self._size._set_width = method1
        
#    def __dealloc__(self):
#        del self.p_this

#    property rotation:
#        def __get__(self):
#            return self.p_this.GetRotation()

#        def __set__(self, float value):
#            self.p_this.SetRotation(value)
#            self._update_target()
##
#    property width:
#        def __get__(self):
#            return self.size[0]

#        def __set__(self, float value):
#            self.size = (value, self.height)
#            self._update_target()
            
#    property height:
#        def __get__(self):
#            return self.size[1]

#        def __set__(self, float value):
#            self.size = (self.width, value)
#            self._update_target()
##
#    property center:
#        def __get__(self):
#            cdef declgraphics.Vector2f center = self.p_this.GetCenter()

#            return Position(center.x, center.y)

#        def __set__(self, value):
#            cdef declgraphics.Vector2f v = Position_to_Vector2f(value)

#            self.p_this.SetCenter(v.x, v.y)
#            self._update_target()

#    property size:
#        def __get__(self):
#            cdef declgraphics.Vector2f size = self.p_this.GetSize()

#            return Size(size.x, size.y)

#        def __set__(self, value):
#            cdef declgraphics.Vector2f v = Position_to_Vector2f(value)

#            self.p_this.SetSize(v.x, v.y)
#            self._update_target()

#    property viewport:
#        def __get__(self):
#            cdef declgraphics.FloatRect *p = new declgraphics.FloatRect()
#            p[0] = self.p_this.GetViewport()

#            return FloatRect_to_Rectangle(p)

#        def __set__(self, viewport):
#            self.p_this.SetViewport(Rectangle_to_FloatRect(viewport))
#            self._update_target()

#    @classmethod
#    def from_center_and_size(cls, center, size):
#        cdef declgraphics.Vector2f cpp_center = Position_to_Vector2f(center)
#        cdef declgraphics.Vector2f cpp_size = Position_to_Vector2f(size)
        
#        cdef declgraphics.View *p
#        p = new declgraphics.View(cpp_center, cpp_size)

#        return wrap_view_instance(p, None)
        
#    @classmethod
#    def from_rectangle(cls, rectangle):
#        cdef declsystem.FloatRect cpp_rectangle = Rectangle_to_FloatRect(rectangle)
#        cdef declgraphics.View *p = new declgraphics.View(cpp_rectangle)

#        return wrap_view_instance(p, None)

#    def _update_target(self):
#        if self.render_target is not None:
#            self.render_target.view = self

#    def move(self, float x, float y):
#        self.p_this.Move(x, y)
#        self._update_target()

#    def reset(self, rectangle):
#        self.p_this.Reset(Rectangle_to_FloatRect(rectangle))
#        self._update_target()

#    def rotate(self, float angle):
#        self.p_this.Rotate(angle)
#        self._update_target()

#    def zoom(self, float factor):
#        self.p_this.Zoom(factor)
#        self._update_target()


#cdef View wrap_view_instance(declgraphics.View *p_cpp_view, object window):
#    cdef View ret = View.__new__(View)

#    ret.p_this = p_cpp_view
#    ret.render_target = window

#    return ret


#cdef class Shader:
#    cdef declgraphics.Shader *p_this

#    IS_AVAILABLE = declgraphics.shader.IsAvailable()

#    def __init__(self):
#        raise NotImplementedError("Use class methods like Shader.load_from_file() to create Shader objects")

#    def __dealloc__(self):
#        del self.p_this

#    property current_texture:
#        def __set__(self, char* value):
#            self.p_this.SetCurrentTexture(value)

#    @classmethod
#    def load_from_file(cls, filename):
#        cdef declgraphics.Shader *p = new declgraphics.Shader()

#        bFilename = filename.encode('UTF-8')
#        if p.LoadFromFile(bFilename):
#            return wrap_shader_instance(p)
#        else:
#            raise SFMLException()

#    @classmethod
#    def load_from_memory(cls, char* shader):
#        cdef declgraphics.Shader *p = new declgraphics.Shader()

#        if p.LoadFromMemory(shader):
#            return wrap_shader_instance(p)
#        else:
#            raise SFMLException()

#    def bind(self):
#        self.p_this.Bind()

#    def set_parameter(self, char *name, float x, y=None, z=None, w=None):
#        if y is None:
#            self.p_this.SetParameter(name, x)
#        elif z is None:
#            self.p_this.SetParameter(name, x, y)
#        elif w is None:
#            self.p_this.SetParameter(name, x, y, z)
#        else:
#            self.p_this.SetParameter(name, x, y, z, w)
    
#    def set_texture(self, char *name, Texture texture):
#        self.p_this.SetTexture(name, texture.p_this[0])

#    def set_current_texture(self, char* name):
#        self.p_this.SetCurrentTexture(name)

#    def unbind(self):
#        self.p_this.Unbind()


#cdef Shader wrap_shader_instance(declgraphics.Shader *p_cpp_instance):
#    cdef Shader ret = Shader.__new__(Shader)

#    ret.p_this = p_cpp_instance

#    return ret


#cdef class RenderTarget:
#    cdef declgraphics.RenderTarget *p_this

#    def __cinit__(self, *args, **kwargs):
#        pass

#    def __init__(self, *args, **kwargs):
#        if self.__class__ == RenderTarget:
#            raise NotImplementedError('RenderTarget is abstact')

#    property default_view:
#        def __get__(self):
#            cdef declgraphics.View *p = new declgraphics.View()

#            p[0] = self.p_this.GetDefaultView()

#            return wrap_view_instance(p, None)

#    property view:
#        def __get__(self):
#            cdef declgraphics.View *p = new declgraphics.View()

#            p[0] = self.p_this.GetView()

#            return wrap_view_instance(p, self)

#        def __set__(self, View value):
#            self.p_this.SetView(value.p_this[0])

#    def clear(self, Color color=None):
#        if color is None:
#            self.p_this.Clear()
#        else:
#            self.p_this.Clear(color.p_this[0])

#    def draw(self, Drawable drawable, Shader shader=None):
#        if shader is None:
#            self.p_this.Draw(drawable.p_this[0])
#        else:
#            self.p_this.Draw(drawable.p_this[0], shader.p_this[0])

#    def get_viewport(self, View view):
#        cdef declgraphics.IntRect *p = new declgraphics.IntRect()

#        p[0] = self.p_this.GetViewport(view.p_this[0])

#        return IntRect_to_Rectangle(p)

#    def convert_coords(self, unsigned int x, unsigned int y, View view=None):
#        cdef declgraphics.Vector2f res

#        if view is None:
#            res = self.p_this.ConvertCoords(x, y)
#        else:
#            res = self.p_this.ConvertCoords(x, y, view.p_this[0])

#        return (res.x, res.y)

#    def restore_gl_states(self):
#        self.p_this.RestoreGLStates()

#    def save_gl_states(self):
#        self.p_this.SaveGLStates()


#cdef api object wrap_render_target_instance(declgraphics.RenderTarget *p):
#    cdef RenderTarget ret = RenderTarget.__new__(RenderTarget)
#    ret.p_this = p
    
#    return ret
    
   
##sfml/cython/graphics.pyx:2235:30: C class may only have one base class
##no other choice than making nearly two same class instead of 
##subclassing
#cdef class RenderWindow(Window):
#    def __cinit__(self, VideoMode mode, title, int style=Style.DEFAULT, ContextSettings settings=None):
#        encoded_title = title.encode(u"ISO-8859-1")
#        if settings is None:
#            self.p_this = <declgraphics.Window*>new declgraphics.RenderWindow(mode.p_this[0], encoded_title, style)
#        else:
#            self.p_this = <declgraphics.Window*>new declgraphics.RenderWindow(mode.p_this[0], encoded_title, style, settings.p_this[0])

#    def __dealloc__(self):
#        del self.p_this

#    property default_view:
#        def __get__(self):
#            cdef declgraphics.View *p = new declgraphics.View()

#            p[0] = (<declgraphics.RenderWindow*>self.p_this).GetDefaultView()

#            return wrap_view_instance(p, None)

#    property view:
#        def __get__(self):
#            cdef declgraphics.View *p = new declgraphics.View()

#            p[0] = (<declgraphics.RenderWindow*>self.p_this).GetView()

#            return wrap_view_instance(p, self)

#        def __set__(self, View value):
#            (<declgraphics.RenderWindow*>self.p_this).SetView(value.p_this[0])

#    def clear(self, Color color=None):
#        if color is None:
#            (<declgraphics.RenderWindow*>self.p_this).Clear()
#        else:
#            (<declgraphics.RenderWindow*>self.p_this).Clear(color.p_this[0])

#    def draw(self, Drawable drawable, Shader shader=None):
#        if shader is None:
#            (<declgraphics.RenderWindow*>self.p_this).Draw(drawable.p_this[0])
#        else:
#            (<declgraphics.RenderWindow*>self.p_this).Draw(drawable.p_this[0], shader.p_this[0])

#    def get_viewport(self, View view):
#        cdef declgraphics.IntRect *p = new declgraphics.IntRect()

#        p[0] = (<declgraphics.RenderWindow*>self.p_this).GetViewport(view.p_this[0])

#        return IntRect_to_Rectangle(p)

#    def convert_coords(self, unsigned int x, unsigned int y, View view=None):
#        cdef declgraphics.Vector2f res

#        if view is None:
#            res = (<declgraphics.RenderWindow*>self.p_this).ConvertCoords(x, y)
#        else:
#            res = (<declgraphics.RenderWindow*>self.p_this).ConvertCoords(x, y, view.p_this[0])

#        return (res.x, res.y)

#    def restore_gl_states(self):
#        (<declgraphics.RenderWindow*>self.p_this).RestoreGLStates()

#    def save_gl_states(self):
#        (<declgraphics.RenderWindow*>self.p_this).SaveGLStates()

#    @classmethod
#    def from_window_handle(cls, unsigned long window_handle, ContextSettings settings=None):
#        cdef declgraphics.RenderWindow *p = NULL

#        if settings is None:
#            p = new declgraphics.RenderWindow(<declwindow.WindowHandle>window_handle)
#        else:
#            p = new declgraphics.RenderWindow(<declwindow.WindowHandle>window_handle, settings.p_this[0])

#        return wrap_render_window_instance(p)


#cdef class HandledWindow(RenderTarget):
#    def __cinit__(self):
#        self.p_this = <declgraphics.RenderTarget*>new declgraphics.RenderWindow()
        
#    def __dealloc__(self):
#        del self.p_this

#    def __iter__(self):
#        return self

#    def __next__(self):
#        cdef declwindow.Event p
        
#        if (<declgraphics.RenderWindow*>self.p_this).PollEvent(p):
#            return <object>wrap_event_instance(&p)

#        raise StopIteration

#    property events:
#        def __get__(self):
#            return self
            
#    property active:
#        def __set__(self, bint value):
#            (<declgraphics.RenderWindow*>self.p_this).SetActive(value)

#    property framerate_limit:
#        def __set__(self, int value):
#            (<declgraphics.RenderWindow*>self.p_this).SetFramerateLimit(value)

#    property frame_time:
#        def __get__(self):
#            return (<declgraphics.RenderWindow*>self.p_this).GetFrameTime()

#    property width:
#        def __get__(self):
#            return self.p_this.GetWidth()

#        def __set__(self, unsigned int value):
#            self.size = (value, self.height)

#    property height:
#        def __get__(self):
#            return self.p_this.GetHeight()

#        def __set__(self, unsigned int value):
#            self.size = (self.width, value)

#    property size:
#        def __get__(self):
#            return (self.width, self.height)

#        def __set__(self, tuple value):
#            x, y = value
#            (<declgraphics.RenderWindow*>self.p_this).SetSize(x, y)

#    property joystick_threshold:
#        def __set__(self, bint value):
#            (<declgraphics.RenderWindow*>self.p_this).SetJoystickThreshold(value)

#    property key_repeat_enabled:
#        def __set__(self, bint value):
#            (<declgraphics.RenderWindow*>self.p_this).EnableKeyRepeat(value)

#    property opened:
#        def __get__(self):
#            return (<declgraphics.RenderWindow*>self.p_this).IsOpened()

#    property position:
#        def __set__(self, tuple value):
#            x, y = value
#            (<declgraphics.RenderWindow*>self.p_this).SetPosition(x, y)

#    property settings:
#        def __get__(self):
#            cdef declwindow.ContextSettings *p = new declwindow.ContextSettings()

#            p[0] = (<declgraphics.RenderWindow*>self.p_this).GetSettings()

#            return wrap_context_settings_instance(p)

#    property show_mouse_cursor:
#        def __set__(self, bint value):
#            (<declgraphics.RenderWindow*>self.p_this).ShowMouseCursor(value)

#    property system_handle:
#        def __get__(self):
#            return <unsigned long>(<declgraphics.RenderWindow*>self.p_this).GetSystemHandle()

#    property title:
#        def __set__(self, title):
#            encoded_title = title.encode(u"ISO-8859-1")
#            (<declgraphics.RenderWindow*>self.p_this).SetTitle(encoded_title)

#    property vertical_synchronization:
#        def __set__(self, bint value):
#            (<declgraphics.RenderWindow*>self.p_this).EnableVerticalSync(value)

#    def display(self):
#        (<declgraphics.RenderWindow*>self.p_this).Display()
            
#    def set_icon(self, unsigned int width, unsigned int height, char* pixels):
#        (<declgraphics.RenderWindow*>self.p_this).SetIcon(width, height, <declgraphics.Uint8*>pixels)

#    def show(self, bint show):
#        (<declgraphics.RenderWindow*>self.p_this).Show(show)

#    def create(self, unsigned long window_handle, ContextSettings settings=None):
#            if settings is None:
#                (<declgraphics.RenderWindow*>self.p_this).Create(<declwindow.WindowHandle>window_handle)
#            else:
#                (<declgraphics.RenderWindow*>self.p_this).Create(<declwindow.WindowHandle>window_handle, settings.p_this[0])


#cdef RenderWindow wrap_render_window_instance(declgraphics.RenderWindow *p_cpp_instance):
#    cdef RenderWindow ret = RenderWindow.__new__(RenderWindow)

#    ret.p_this = <declgraphics.Window*>p_cpp_instance

#    return ret


#cdef class RenderTexture(RenderTarget):
#    def __cinit__(self):
#        self.p_this = <declgraphics.RenderTarget*>new declgraphics.RenderTexture()
    
#    def __init__(self, unsigned int width, unsigned int height,
#                 bint depth=False):
#        self.create(width, height, depth)
    
#    def __dealloc__(self):
#        del self.p_this
    
#    property active:
#        def __set__(self, bint active):
#            (<declgraphics.RenderTexture*>self.p_this).SetActive(active)

#    property texture:
#        def __get__(self):
#            return wrap_texture_instance(<declgraphics.Texture*>&(<declgraphics.RenderTexture*>self.p_this).GetTexture(), False)

#    property width:
#        def __get__(self):
#            return self.p_this.GetWidth()

#        def __set__(self, unsigned int value):
#            self.size = (value, self.height)

#    property height:
#        def __get__(self):
#            return self.p_this.GetHeight()
        
#        def __set__(self, unsigned int value):
#            self.size = (self.width, value)

#    property size:
#        def __get__(self):
#            return (self.width, self.height)

#        def __set__(self, tuple value):
#            x, y = value
#            self.create(x, y)

#    property smooth:
#        def __get__(self):
#            return (<declgraphics.RenderTexture*>self.p_this).IsSmooth()
        
#        def __set__(self, bint smooth):
#            (<declgraphics.RenderTexture*>self.p_this).SetSmooth(smooth)

#    def create(self, unsigned int width, unsigned int height, bint depth=False):
#        (<declgraphics.RenderTexture*>self.p_this).Create(width, height, depth)

#    def display(self):
#        (<declgraphics.RenderTexture*>self.p_this).Display()


#cdef class Renderer:
#    TRIANGLE_LIST = declgraphics.primitive.TriangleList
#    TRIANGLE_STRIP = declgraphics.primitive.TriangleStrip
#    TRIANGLE_FAN = declgraphics.primitive.TriangleFan
#    QUAD_LIST = declgraphics.primitive.QuadList
    
#    cdef declgraphics.Renderer *p_this

#    def initialize(self):
#        self.p_this.Initialize()
        
#    def save_gl_states(self):
#        self.p_this.SaveGLStates()
        
#    def restore_gl_states(self):
#        self.p_this.RestoreGLStates()
        
#    def clear(self, Color color):
#        self.p_this.Clear(color.p_this[0])
        
#    def push_states(self):
#        self.p_this.PushStates()
        
#    def pop_states(self):
#        self.p_this.PopStates()
        
#    def set_model_view(self, Matrix3 matrix):
#        self.p_this.SetModelView(matrix.p_this[0])
    
#    def apply_model_view(self, Matrix3 matrix):
#        self.p_this.ApplyModelView(matrix.p_this[0])
        
#    def set_projection(self, Matrix3 matrix):
#        self.p_this.SetProjection(matrix.p_this[0])
        
#    def set_color(self, Color color):
#        self.p_this.SetColor(color.p_this[0])
        
#    def apply_color(self, Color color):
#        self.p_this.SetColor(color.p_this[0])
        
#    def set_viewport(self, IntRect viewport):
#        self.p_this.SetViewport(viewport.p_this[0])
        
#    def set_blend_mode(self, int value):
#        self.p_this.SetBlendMode(<declgraphics.blendmode.Mode>value)
        
#    def set_texture(self, Texture texture):
#        self.p_this.SetTexture(texture.p_this)
        
#    def set_shader(self, Shader shader):
#        self.p_this.SetShader(shader.p_this)
        
#    def begin(self, int value):
#        self.p_this.Begin(<declgraphics.primitive.PrimitiveType>value)
        
#    def end(self):
#        self.p_this.End()
    

#cdef api object wrap_renderer_instance(declgraphics.Renderer *p_cpp_instance):
#    cdef Renderer ret = Renderer.__new__(Renderer)
    
#    ret.p_this = p_cpp_instance

#    return ret