if ( typeof DOM == "undefined" ) DOM = {};

DOM.Ready = {};

DOM.Ready.VERSION = '0.14';

DOM.Ready.finalTimeout = 15;
DOM.Ready.timerInterval = 50;

/* This works for Mozilla */
if ( document.addEventListener ) {
    document.addEventListener
        ( "DOMContentLoaded", function () { DOM.Ready._isDone = 1; }, false );
}

DOM.Ready._checkDOMReady = function () {
    if ( DOM.Ready._isReady ) return DOM.Ready._isReady;

    if (    typeof document.getElementsByTagName != 'undefined'
         && typeof document.getElementById != 'undefined' 
         && ( document.getElementsByTagName('body')[0] != null
              || document.body != null ) ) {

        DOM.Ready._isReady = 1;
    }

    return DOM.Ready._isReady;

};

DOM.Ready._checkDOMDone = function () {
    /* IE (and Opera?) only */
    if ( document.readyState
         && ( document.readyState == "interactive"
              || document.readyState == "complete" ) ) {
        return 1;
    }

    return DOM.Ready._isDone;
};

DOM.Ready.onDOMReady = function (callback) {
    if ( DOM.Ready._checkDOMReady() ) {
        callback();
    }
    else {
        DOM.Ready._onDOMReadyCallbacks.push(callback);
    }
}

DOM.Ready.onDOMDone = function (callback) {
    if ( DOM.Ready._checkDOMDone() ) {
        callback();
    }
    else {
        DOM.Ready._onDOMDoneCallbacks.push(callback);
    }
}

DOM.Ready.onIdReady = function ( id, callback ) {
    if ( DOM.Ready._checkDOMReady() ) {
        var elt = document.getElementById(id);
        if (elt) {
            callback(elt);
            return;
        }
    }

    var callback_array = DOM.Ready._onIdReadyCallbacks[id];
    if ( ! callback_array ) {
        callback_array = [];
    }
    callback_array.push(callback);

    DOM.Ready._onIdReadyCallbacks[id] = callback_array;
}

DOM.Ready._runDOMReadyCallbacks = function () {
    for ( var i = 0; i < DOM.Ready._onDOMReadyCallbacks.length; i++ ) {
        DOM.Ready._onDOMReadyCallbacks[i]();
    }

    DOM.Ready._onDOMReadyCallbacks = [];
}

DOM.Ready._runDOMDoneCallbacks = function () {
    for ( var i = 0; i < DOM.Ready._onDOMDoneCallbacks.length; i++ ) {
        DOM.Ready._onDOMDoneCallbacks[i]();
    }

    DOM.Ready._onDOMDoneCallbacks = [];
}

DOM.Ready._runIdCallbacks = function () {
    for ( var id in DOM.Ready._onIdReadyCallbacks ) {
        // protect against changes to Object (ala prototype's extend)
        if ( ! DOM.Ready._onIdReadyCallbacks.hasOwnProperty(id) ) {
            continue;
        }

        var elt = document.getElementById(id);

        if (elt) {
            for ( var i = 0; i < DOM.Ready._onIdReadyCallbacks[id].length; i++) {
                DOM.Ready._onIdReadyCallbacks[id][i](elt);
            }

            delete DOM.Ready._onIdReadyCallbacks[id];
        }
    }
}

DOM.Ready._runReadyCallbacks = function () {
    if ( DOM.Ready._inRunReadyCallbacks ) return;

    DOM.Ready._inRunReadyCallbacks = 1;

    if ( DOM.Ready._checkDOMReady() ) {
        DOM.Ready._runDOMReadyCallbacks();

        DOM.Ready._runIdCallbacks();
    }

    if ( DOM.Ready._checkDOMDone() ) {
        DOM.Ready._runDOMDoneCallbacks();
    }

    DOM.Ready._timePassed += DOM.Ready._lastTimerInterval;

    if ( ( DOM.Ready._timePassed / 1000 ) >= DOM.Ready.finalTimeout ) {
        DOM.Ready._stopTimer();
    }

    DOM.Ready._inRunReadyCallbacks = 0;
}

DOM.Ready._startTimer = function () {
    DOM.Ready._lastTimerInterval = DOM.Ready.timerInterval;
    DOM.Ready._intervalId = setInterval( DOM.Ready._runReadyCallbacks, DOM.Ready.timerInterval );
};

DOM.Ready._stopTimer = function () {
    clearInterval( DOM.Ready._intervalId );
    DOM.Ready._intervalId = null;
}

DOM.Ready._resetClass = function () {
    DOM.Ready._stopTimer();

    DOM.Ready._timePassed = 0;

    DOM.Ready._isReady = 0;
    DOM.Ready._isDone = 0;

    DOM.Ready._onDOMReadyCallbacks = [];
    DOM.Ready._onDOMDoneCallbacks = [];
    DOM.Ready._onIdReadyCallbacks = {};

    DOM.Ready._startTimer();
}

DOM.Ready._resetClass();

DOM.Ready.runCallbacks = function () { DOM.Ready._runReadyCallbacks() };


/*

*/
