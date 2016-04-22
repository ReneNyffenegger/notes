function q() {
  var s = document.getElementById('q').value; 
  s = s.replace(/ /g, '+');

  location.replace('https://www.google.ch/search?q=inurl:notes+site:renenyffenegger.ch+' + s)
}
