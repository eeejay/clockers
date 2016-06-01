var adjustButton = document.getElementById("adjust");
var autotimeButton = document.getElementById("autotime");
var zeroButton = document.getElementById("zero");
var tzselect = document.getElementById("timezones");
var movementSelect = document.getElementById("movements");

function autoEnabled() {
  return JSON.parse(autotimeButton.getAttribute("aria-pressed"));
}

autotimeButton.addEventListener("click", function() {
  var toggled = autoEnabled();
  autotimeButton.setAttribute("aria-pressed", !toggled);
});

function fetchJSON(url) {
  if (window.fetch) {
    return window.fetch(url).then(function (r) {
      return r.json();
    });
  }

  return new Promise(function(resolve) {
    var xmlhttp = new XMLHttpRequest();

    xmlhttp.onreadystatechange = function() {
      if (xmlhttp.readyState == 4 && xmlhttp.status == 200) {
        resolve(JSON.parse(xmlhttp.responseText));
      }
    };

    xmlhttp.open("GET", url, true);
    xmlhttp.send();
  });
}

fetchJSON("/control/timezones").then(function(j) {
  for (var tz of j.all) {
    var option = document.createElement("option");
    option.value = tz;
    option.textContent = tz;
    tzselect.appendChild(option);
  }
  tzselect.value = j.selected;
});

fetchJSON("/control/movements").then(function(j) {
  for (var movement in j.all) {
    var option = document.createElement("option");
    option.value = movement;
    option.textContent = j.all[movement].label;
    movementSelect.appendChild(option);
  }
  movementSelect.value = j.selected;
});

adjustButton.addEventListener("click", function() {
  var action;
  var payload = {
    movement: movementSelect.value,
    timezone: document.getElementById("timezones").value,
    customOffset: 0
  };
  if (!autoEnabled()) {
    var d = new Date();
    var customTime = Date.UTC(d.getFullYear(), d.getMonth(), d.getDay(),
      document.getElementById("hours").value,
      document.getElementById("minutes").value,
      document.getElementById("seconds").value);
    payload.customOffset = customTime - d;
  }

  var xmlhttp = new XMLHttpRequest();

  xmlhttp.open("POST", "/control/adjust", true);
  xmlhttp.setRequestHeader("Content-Type", 'application/json');
  xmlhttp.setRequestHeader("Accept", 'application/json');
  xmlhttp.send(JSON.stringify(payload));
});

zeroButton.addEventListener("click", function() {
  fetch("/control/zero");
});
