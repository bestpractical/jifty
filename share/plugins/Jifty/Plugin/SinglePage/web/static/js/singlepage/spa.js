(function($) {
    SPA = {
        initialHash: "spa_start",
        currentHash: null,
        currentLocation: null,
        historyChange: function(newLocation, historyData, first) {

            /* reload if user goes to the first page */
            if (newLocation == SPA.initialHash) {
                location.href = location.pathname;
            }

            if (first) {
                dhtmlHistory.add(newLocation, historyData);
            } else {
                if (historyStorage.hasKey(newLocation)) {
                    Jifty.update(historyStorage.get(newLocation), "");
                }
            }
        }
    };

    /*
     * If user paste /#/abc in location bar, or click the reload button,
     * then we should redirect him to the right page
     */
    SPA.currentHash = location.hash;
    if (SPA.currentHash.length) {
        if (SPA.currentHash.charAt(0) == '#' && SPA.currentHash.charAt(1) == '/') {
            SPA.currentLocation = SPA.currentHash.slice(1);
            location.href = SPA.currentLocation;
        }
    }

    $(document).ready(function(){
        dhtmlHistory.initialize();
        dhtmlHistory.addListener(SPA.historyChange);
        if (dhtmlHistory.isFirstLoad()) {
            dhtmlHistory.add(SPA.initialHash, "");
        }
    });
    
})(jQuery);


window.dhtmlHistory.create({
    toJSON: function(o) {
        return JSON.stringify(o);
    }
    , fromJSON: function(s) {
        return JSON.parse(s);
    }
});
