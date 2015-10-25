
function usesnap(x,y)
 {

         var logo = Snap.select("#svg_obj"),
         circle = logo.select("#poi");
     circle.animate(
         {
             transform: "t"+x+","+y
         }, 1000);
}


