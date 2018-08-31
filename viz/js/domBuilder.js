d3.json("./data/winners_byClaim.json", function(categories) {

  // get rid of the "other" one
  categories = categories.filter(function(item) {
     return item.Catg.toLowerCase() !== "other";
  });
  // sort em
  //*
  categories.sort(function(a, b) {
      var textA = a.Catg.toUpperCase();
      var textB = b.Catg.toUpperCase();
      return (textA < textB) ? -1 : (textA > textB) ? 1 : 0;
  });
  //*/

  /*
  categories.sort(function(a, b) {
      return (a.globalAvgVal > b.globalAvgVal) ? -1 : (a.globalAvgVal < b.globalAvgVal) ? 1 : 0;
  });
  //*/


  var theRow = d3.select(".row");
  var myMultiple = theRow.selectAll(".categoryDiv")
                          .data(categories)
                          .enter()
                          .append("div")
                          .attr("class","categoryDiv col-12 col-sm-6 col-md-4");
  /*
  myMultiple.append("img")
            .attr("class","img-fluid")
            .attr("src",function(d){return ("./img/contour_byClaim/contourMap_"+d.idx+".png");});
  */
  var myFullImg = myMultiple.append("a")
            .attr("class","img-fluid progressive replace")
            .attr("href",function(d){return ("./img/contour_byClaim/contourMap_"+d.idx+".png");});
  myFullImg.append("img")
            .attr("class","img-fluid preview")
            .attr("alt","image")
            .attr("src","./img/preview.png");



  myMultiple.append("h3")
            .attr("class","categoryTitle")
            .html(function(d){return d.Catg});
  myMultiple.append("p")
            .attr("class","categoryAvg")
            .html(function(d){return ("National Average: "+d3.format(".1%")(d.globalAvgVal)+" claims are "+d.Catg);});
  myMultiple.append("p")
            .attr("class","categoryWinner")
            .html(function(d){return (d.Name+" has "+d3.format(".2r")(d.valRatio)+" times as much");});


});
