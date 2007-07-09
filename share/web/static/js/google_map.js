// XXX: move me to Plugin/GoogleMap's share when that works

if (GMap2) {
    //document.body.onunload = "GUnload()";

function EditLocationControl() {
}
EditLocationControl.prototype = new GControl();


EditLocationControl.prototype.initialize = function(map) {
  var container = document.createElement("div");

  var EditDiv = document.createElement("div");
  this.setButtonStyle_(EditDiv);
  container.appendChild(EditDiv);
  EditDiv.appendChild(document.createTextNode("Edit"));
  var editctl = this;
  GEvent.addDomListener(EditDiv, "click", function() {
    if (editctl.editing) {
        var point = map._jifty_location.getPoint();
	$(map._jifty_form_x).value = point.lng()
	$(map._jifty_form_y).value = point.lat()
	EditDiv.innerHTML = "Edit";
    }
    else {
	EditDiv.innerHTML = "Done";
	editctl.editing = true;
    }
  });

  map.getContainer().appendChild(container);
  map._jifty_edit_control = this;
  this.editing = false;
  return container;
}


EditLocationControl.prototype.getDefaultPosition = function() {
  return new GControlPosition(G_ANCHOR_BOTTOM_RIGHT, new GSize(7, 7));
}

EditLocationControl.prototype.setButtonStyle_ = function(button) {
  button.style.textDecoration = "underline";
  button.style.color = "#0000cc";
  button.style.backgroundColor = "white";
  button.style.font = "small Arial";
  button.style.fontSize = "0.8em";
  button.style.border = "1px solid black";
  button.style.padding = "2px";
  button.style.marginBottom = "3px";
  button.style.textAlign = "center";
  button.style.width = "4em";
  button.style.cursor = "pointer";
}


}
