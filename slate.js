// Have a pointer to the screen where you're currently in
// (not slate.screen() default, since you want to have reference
// to latest screen where window was thrown)
var focusedScreen = slate.screen();
var screens = getAllScreens();

// ================================
// HELPER FUNCTIONS
// ================================
function getAllScreens() {
    var screens = [];
    slate.eachScreen(function (screen) {
        screens.push(screen);
    });
    return screens;
}

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

// ================================
// RESIZING FUNCTIONS
// ================================
var maximize = function (screen) {
    screen = screen || slate.screen();
    var rect = screen.visibleRect();
    return slate.operation('move', {
        x : rect.x,
        y : rect.y,
        width : rect.width,
        height : rect.height,
        screen : screen
    });
};

function getPushFn(direction) {
    const coords = {
        up: "bar-resize:screenSizeY/2",
        down: "bar-resize:screenSizeY/2",
        left: "bar-resize:screenSizeX/2",
        right: "bar-resize:screenSizeX/2",
    }

    return function (screen) {
        screen = screen || focusedScreen;
        return slate.operation('push', {
            direction: direction,
            style: coords[direction],
            screen: screen
        });
    };
}

function getCornerFn(direction) {
    return function (screen) {
        screen = screen || focusedScreen;
        return slate.operation('corner', {
            direction: direction,
            width: "screenSizeX/2",
            height: "screenSizeY/2",
            //screen: screen
        });
    };
}

function throwToScreenMax(screen) {
    return slate.operation('throw', {
        screen: screen,
        width: "screenSizeX",
        height: "screenSizeY"
    });
};

// ================================
// KEY BINDINGS
// ================================

// --------------------------------
// MAXIMIZE IN CURRENT WINDOW
// --------------------------------
slate.bind('space:alt,cmd,ctrl', function (window) {
    window.doOperation(maximize());
});

// ------------------------
// PUSH TO DIRECTIONS
// ------------------------
// Push window to top current screen
slate.bind('k:alt,cmd,ctrl', function (window) {
    window.doOperation(getPushFn('up')());
});

// Push window to bottom current screen
slate.bind('j:ctrl,alt,cmd', function (window) {
    window.doOperation(getPushFn('down')());
});

// Push window to left current screen
slate.bind('h:ctrl,alt,cmd', function (window) {
    window.doOperation(getPushFn('left')());
});

// Push window to right current screen
slate.bind('l:ctrl,alt,cmd', function (window) {
    window.doOperation(getPushFn('right')());
});

// -------------------------
// PUSH TO CORNERS
// -------------------------
// Push window to upper left current screen
slate.bind('u:ctrl,alt,cmd', function (window) {
    window.doOperation(getCornerFn('top-left')());
});

// Push window to upper right current screen
slate.bind('i:ctrl,alt,cmd', function (window) {
    window.doOperation(getCornerFn('top-right')());
});

// Push window to bottom left current screen
slate.bind('n:ctrl,alt,cmd', function (window) {
    window.doOperation(getCornerFn('bottom-left')());
});

// Push window to bottom right current screen
slate.bind('m:ctrl,alt,cmd', function (window) {
    window.doOperation(getCornerFn('bottom-right')());
});


// -------------------------
// THROWING TO SCREENS
// -------------------------
// Throw left and maximize
slate.bind('h:ctrl,alt,cmd,shift', function(window) {
    screens = getAllScreens();
    var previousScreen = getPreviousScreen();
    if (previousScreen) {
        window.doOperation(throwToScreenMax(previousScreen));
        focusedScreen = previousScreen;
    }
});

// Throw right and maximize
slate.bind('l:ctrl,alt,cmd,shift', function(window) {
    screens = getAllScreens();
    var nextScreen = getNextScreen();
    if (nextScreen) {
        window.doOperation(throwToScreenMax(nextScreen));
        focusedScreen = nextScreen;
    }
});
