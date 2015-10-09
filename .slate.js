// Have a pointer to the screen where you're currently in
// (not slate.screen() default, since you want to have reference
// to latest screen where window was thrown)
var focusedScreen = slate.screen();

// Get all screens
var screens = [];
slate.eachScreen(function (screen) {
    screens.push(screen);
});

function getPreviousScreen () {
    for (var i=0; i < screens.length; i++) {
        try {
            if (screens[i].id() === focusedScreen.id()) {
                return screens[i-1];
            }
        }
        catch (indexOutOfBoundsError) {
            // if caught, means tried accessing the screen before first screen (screens[-1])
            // return false, saying there is no previous screen
            return false;
        }
    }
}

function getNextScreen () {
    for (var i=0; i < screens.length; i++) {
        try {
            if (screens[i].id() === focusedScreen.id()) {
                return screens[i+1];
            }
        }
        catch (indexOutOfBoundsError) {
            // if caught, means tried accessing the screen after last screen (screens[screens.length])
            // return false, saying there is no next screen
            return false;
        }
    }
}
// Resizing/Pushing functions
var maximize = function (screen) {
    screen = screen || focusedScreen;
    var rect = screen.visibleRect();
    return slate.operation('move', {
        x : rect.x,
        y : rect.y,
        width : rect.width,
        height : rect.height,
        screen : screen
    });
};

var pushTop = function (screen) {
    screen = screen || focusedScreen;
    return slate.operation('push', {
        direction: 'up',
        style: "bar-resize:screenSizeY/2",
        screen: screen
    });
};

var pushBottom = function (screen) {
    screen = screen || focusedScreen;
    return slate.operation('push', {
        direction: 'down',
        style: "bar-resize:screenSizeY/2",
        screen: screen
    });
};

var pushLeft = function (screen) {
    screen = screen || focusedScreen;
    return slate.operation('push', {
        direction: 'left',
        style: "bar-resize:screenSizeX/2",
        screen: screen
    });
};

var pushRight = function (screen) {
    screen = screen || focusedScreen;
    return slate.operation('push', {
        direction: 'right',
        style: "bar-resize:screenSizeX/2",
        screen: screen
    });
};

// Throwing to other screens
var throwToScreenMax = function (screen) {
    return slate.operation('throw', {
        screen: screen,
        width: "screenSizeX",
        height: "screenSizeY"
    });
};

// === KEY BINDINGS ===

// --- PUSHING ---

// all inside anonymous functions, otherwise
// screen objects inside of operations called
// (maximize, pushToTop,etc) would hold a static
// reference to initial focusedScreen and would
// not updated those inner screens as focusedScreen
// is dynamically changed

// Maximize in current window
slate.bind('m:alt,cmd,ctrl', function (window) {
    window.doOperation(maximize());
});

// // Push window to top current screen
slate.bind('k:alt,cmd,ctrl', function (window) {
    window.doOperation(pushTop());
});

// Push window to bottom current screen
slate.bind('j:ctrl,alt,cmd', function (window) {
    window.doOperation(pushBottom());
});

// Push window to left current screen
slate.bind('h:ctrl,alt,cmd', function (window) {
    window.doOperation(pushLeft());
});

// Push window to right current screen
slate.bind('l:ctrl,alt,cmd', function (window) {
    window.doOperation(pushRight());
});


// --- THROWING ---

// Throw left and maximize
slate.bind('h:ctrl,alt,cmd,shift', function(window) {
    var previousScreen = getPreviousScreen();
    if (previousScreen) {
        window.doOperation(throwToScreenMax(previousScreen));
        focusedScreen = previousScreen;
    }
});

// Throw right and maximize
slate.bind('l:ctrl,alt,cmd,shift', function(window) {
    var nextScreen = getNextScreen();
    if (nextScreen) {
        window.doOperation(throwToScreenMax(nextScreen));
        focusedScreen = nextScreen;
    }
});
