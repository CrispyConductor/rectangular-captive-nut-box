$fa=2;
$fs=0.7;

module CaptiveNutBox(
    part, // which part to produce, "box" or "lid"
    size, // interior dimensions of box
    nutSize=8.731, // size of the nut, face to face
    nutHeight=3.175, // height/thickness of the nut
    screwHoleDiameter=4.5, // diameter of the hole for a free fit of the screw
    wallThick=2, // box wall thickness
    bottomThick=2, // box floor thickness
    topThick=3, // thickness of box lid
    nutWallThick=2, // thickness of walls and bottom around nuts
    nutTopWallThick=2.5, // thickness of wall above nut, which takes the screw pressure
    nutClearance=0.3, // clearance between nut and each surrounding wall
    nutHeightClearance=0.3, // clearance between the top and bottom walls and the nut
    retainingClipClearance=0, // clearance between retaining clip and nut; negative values provide a force fit
    retainingClipThick=0.5, // depth of the nut retaining clip; larger values make stronger clips
    nutRemovalHoleDiameter=1.75, // diameter of hole on exterior to aid in removing the nuts
    maxEmbossThick=1, // maximum depth of emboss
    countersinkScrews=false,
    countersinkAngle=82,
    countersinkDepth=2.54
) {
    // Outer size of box, including walls
    outerSize = [ size[0] + 2*wallThick, size[1] + 2*wallThick, size[2] + bottomThick ];
    
    // Length of one of the hexagonal faces
    nutFaceLength = nutSize / sqrt(3);
    // Point-to-point distance on nut
    nutMaxDiameter = nutFaceLength + nutSize / sqrt(3);
    
    nutCutoutSize = nutSize + nutClearance*2;
    nutCutoutHeight = nutHeight + nutHeightClearance*2;
    nutCutoutFaceLength = nutCutoutSize / sqrt(3);
    nutCutoutMaxDiameter = nutCutoutFaceLength + nutCutoutSize / sqrt(3);
    
    // Diameter of the cylinder the nut fits inside
    nutCylinderDiameter = nutCutoutMaxDiameter + 2*nutWallThick;
    hexConeHeight = nutCutoutMaxDiameter/2 - screwHoleDiameter/2;
    // Height of the cylinder the nut fits inside
    nutCylinderHeight = nutCutoutHeight + nutWallThick + nutTopWallThick + hexConeHeight;
    
    nutHolderX1 = wallThick+nutCylinderDiameter/2;
    nutHolderX2 = wallThick + size[0] - nutCylinderDiameter/2;
    nutHolderY1 = wallThick+nutCylinderDiameter/2;
    nutHolderY2 = wallThick + size[1] - nutCylinderDiameter/2;
    nutHolderZ = outerSize[2] - nutCylinderHeight;
    
    embossThick = min(maxEmbossThick, bottomThick/2, topThick/2, wallThick/2);
    
    minScrewLength = topThick + nutTopWallThick + nutCutoutHeight + hexConeHeight - (countersinkScrews ? countersinkDepth : 0);
    echo("Minimum screw length", minScrewLength);
    
    module RoundedCube(size, radius) {
       hull() {
            translate([ radius, radius, radius ])
                sphere(r=radius);
            translate([ size[0] - radius, radius, radius ])
                sphere(r=radius);
            translate([ size[0] - radius, size[1] - radius, radius ])
                sphere(r=radius);
            translate([ radius, size[1] - radius, radius ])
                sphere(r=radius);
            translate([ radius, radius, size[2] - radius ])
                sphere(r=radius);
            translate([ size[0] - radius, radius, size[2] - radius ])
                sphere(r=radius);
            translate([ size[0] - radius, size[1] - radius, size[2] - radius ])
                sphere(r=radius);
            translate([ radius, size[1] - radius, size[2] - radius ])
                sphere(r=radius);
       };
    };
    
    module CaptiveNutCylinder() {
        
        // Polygon is centered on origin, with "first" point along X axis
        module RegularPolygon(numCorners, outerRadius, faceOnXAxis=false) {
            points = [
                for (pointNum = [0 : numCorners - 1])
                    [cos(pointNum / numCorners * 360) * outerRadius, sin(pointNum / numCorners * 360) * outerRadius]
            ];
            if (faceOnXAxis)
                rotate([0, 0, 360/numCorners/2])
                    polygon(points);
            else
                polygon(points);
        };

        // The 2d shape of the nut holder, from top down
        module xyshape(corner=true) {
            difference() {
                union() {
                    // cylinder exterior
                    circle(r=nutCylinderDiameter/2);
                    // connection to box
                    if (corner) {
                        translate([ -nutCylinderDiameter/2, -nutCylinderDiameter/2 ])
                            square([ nutCylinderDiameter/2, nutCylinderDiameter ]);
                        translate([ -nutCylinderDiameter/2, -nutCylinderDiameter/2 ])
                            square([ nutCylinderDiameter, nutCylinderDiameter/2 ]);
                    } else {
                        translate([ -nutCylinderDiameter/2, -nutCylinderDiameter/2 ])
                            square([ nutCylinderDiameter, nutCylinderDiameter/2 ]);
                    }
                };
                // Screw hole
                circle(r=screwHoleDiameter/2);
            };
        };
        
        module nutcutoutshape() {
            clipWidth = (nutCutoutSize - nutSize) / 2 - retainingClipClearance;
            module clip() {
                d = clipWidth / sqrt(3);
                translate([ 0, nutCutoutFaceLength/2 + nutClearance ])
                    polygon([
                        [ 0, 0 ],
                        [ 0, retainingClipThick + 2 * d ],
                        [ clipWidth, retainingClipThick + d ],
                        [ clipWidth, d ]
                    ]);
            };
            difference() {
                union() {
                    // nut cavity
                    RegularPolygon(6, nutCutoutMaxDiameter/2, true);
                    // slot to slide the nut in
                    translate([ -nutCutoutSize/2, 0 ])
                        square([ nutCutoutSize, nutCylinderDiameter*3 ]);
                };
                // nut retaining clip
                translate([ -nutCutoutSize/2, 0 ])
                    clip();
                translate([ nutCutoutSize/2 - clipWidth, 0 ])
                    clip();
            };
        };

        difference() {
            
            union() {
                // Cylinder exterior
                linear_extrude(nutCylinderHeight)
                    xyshape();
                
                // Bottom support (inverted cone)
                coneUpperRadius = nutCylinderDiameter + (sqrt(2*nutCylinderDiameter*nutCylinderDiameter) - nutCylinderDiameter) / 2;
                intersection() {
                    translate([ -nutCylinderDiameter/2, -nutCylinderDiameter/2, -coneUpperRadius ])
                        cylinder(r1=0, r2=coneUpperRadius, h=coneUpperRadius);
                    linear_extrude(coneUpperRadius*3, center=true)
                        xyshape();
                };
            };
            
            // Nut cutout
            translate([ 0, 0, nutWallThick ])
                linear_extrude(nutCutoutHeight)
                    nutcutoutshape();
            
            // "Hex cone" tapered ceiling for nut, so it's printable
            translate([ 0, 0, nutWallThick+nutCutoutHeight ])
                linear_extrude(hexConeHeight, scale=screwHoleDiameter/nutCutoutMaxDiameter)
                    nutcutoutshape();
        };
    };
    
    module BoxBody() {
        difference() {
            union() {
                // Main box with hollowed center
                difference() {
                    //RoundedCube(size, 1); // This breaks for some reason
                    cube(outerSize);
                    translate([ wallThick, wallThick, bottomThick ])
                        cube([ size[0], size[1], size[2] + 10 ]);
                };
                // Nut holders
                translate([ nutHolderX1, nutHolderY1, nutHolderZ ])
                    CaptiveNutCylinder();
                translate([ nutHolderX2, nutHolderY1, nutHolderZ ])
                    mirror([ 1, 0, 0 ])
                        CaptiveNutCylinder();
                translate([ nutHolderX2, nutHolderY2, nutHolderZ ])
                    rotate([ 0, 0, 180 ])
                        CaptiveNutCylinder();
                translate([ nutHolderX1, nutHolderY2, nutHolderZ ])
                    rotate([ 0, 0, 180 ])
                        mirror([ 1, 0, 0 ])
                            CaptiveNutCylinder();
            };
            
            // Nut removal holes
            nutRemovalHoleLength = (wallThick + nutCutoutMaxDiameter) * 2;
            nutRemovalHoleZ = nutHolderZ + nutWallThick + nutCutoutHeight/2;
            if (nutRemovalHoleDiameter > 0)
                for (x = [ nutHolderX1, nutHolderX2 ])
                    for (y = [ nutHolderY1, nutHolderY2 ])
                        translate([ x, y, nutRemovalHoleZ ])
                            rotate([ 90, 0, 0 ])
                                cylinder(r=nutRemovalHoleDiameter/2, h=nutRemovalHoleLength, center=true);
        };
    };
    
    module BoxWithCutouts() {
        module OnFront(depth)
            if ($children >= 1)
                rotate([ 90, 0, 0 ])
                    linear_extrude(depth*2, center=true)
                        translate([ wallThick, bottomThick ])
                            children();
        module OnLeft(depth)
            if ($children >= 1)
                rotate([ 90, 0, 90 ])
                    linear_extrude(depth*2, center=true)
                        translate([ wallThick, bottomThick ])
                            translate([ size[1]/2, 0 ])
                                mirror([ 1, 0, 0 ])
                                    translate([ -size[1]/2, 0 ])
                                        children();
        module OnRight(depth)
            if ($children >= 1)
                translate([ outerSize[0], 0, 0 ])
                    rotate([ 90, 0, 90 ])
                        linear_extrude(depth*2, center=true)
                            translate([ wallThick, bottomThick ])
                                children();
        module OnBack(depth)
            if ($children >= 1)
                translate([ 0, outerSize[1], 0 ])
                    rotate([ 90, 0, 0 ])
                        linear_extrude(depth*2, center=true)
                            translate([ wallThick, bottomThick ])
                                translate([ size[0]/2, 0 ])
                                    mirror([ 1, 0, 0 ])
                                        translate([ -size[0]/2, 0 ])
                                            children();
        module OnBottom(depth)
            if ($children >= 1)
                linear_extrude(depth)
                    translate([ wallThick, wallThick ])
                        translate([ 0, size[1]/2 ])
                            mirror([ 0, 10, 0 ])
                                translate([ 0, -size[1]/2 ])
                                    children();
        
        difference() {
            BoxBody();
            // Front cutouts
            OnFront(wallThick+nutCylinderDiameter) if($children >= 2) children(1);
            // Left cutouts
            OnLeft(wallThick+nutCylinderDiameter) if($children >= 3) children(2);
            // Right cutouts
            OnRight(wallThick+nutCylinderDiameter) if($children >= 4) children(3);
            // Back cutouts
            OnBack(wallThick+nutCylinderDiameter) if($children >= 5) children(4);
            // Bottom cutouts
            OnBottom(bottomThick) if($children >= 6) children(5);
            // Front emboss
            OnFront(embossThick) if($children >= 8) children(7);
            // Left emboss
            OnLeft(embossThick) if($children >= 9) children(8);
            // Right emboss
            OnRight(embossThick) if($children >= 10) children(9);
            // Back emboss
            OnBack(embossThick) if($children >= 11) children(10);
            // Bottom emboss
            OnBottom(embossThick) if($children >= 12) children(11);
        };
    };
    
    module Lid() {
        countersinkHeight = 100;
        countersinkTopDiameter = 2 * tan(countersinkAngle/2) * (countersinkHeight + screwHoleDiameter * tan(90 - countersinkAngle/2) / 2);
        difference() {
            cube([ outerSize[0], outerSize[1], topThick ]);
            // Screw holes
            for (x = [ nutHolderX1, nutHolderX2 ])
                for (y = [ nutHolderY1, nutHolderY2 ])
                    translate([ x, y, 0 ])
                        cylinder(r=screwHoleDiameter/2, h=topThick*2);
            // Countersinks
            for (x = [ nutHolderX1, nutHolderX2 ])
                for (y = [ nutHolderY1, nutHolderY2 ])
                    translate([ x, y, max(topThick - countersinkDepth, 0.2) ])
                        cylinder(r1=screwHoleDiameter/2, r2=countersinkTopDiameter/2, h=countersinkHeight);
            // Cutouts
            if ($children >= 1)
                linear_extrude(topThick*2)
                    translate([ wallThick, wallThick ])
                        children(0);
            // Emboss
            if ($children >= 2)
                translate([ 0, 0, topThick ])
                    linear_extrude(embossThick)
                        translate([ wallThick, wallThick ])
                            children(1);
        };
    };

    if (part == "box" || part == "both")
        BoxWithCutouts() {
            if($children >= 1) children(0);
            if($children >= 2) children(1);
            if($children >= 3) children(2);
            if($children >= 4) children(3);
            if($children >= 5) children(4);
            if($children >= 6) children(5);
            if($children >= 7) children(6);
            if($children >= 8) children(7);
            if($children >= 9) children(8);
            if($children >= 10) children(9);
            if($children >= 11) children(10);
            if($children >= 12) children(11);
        };

    if (part == "lid")
        Lid() {
            if($children >= 1) children(0);
            if($children >= 7) children(6);
        };
    
    if (part == "both")
        translate([ -outerSize[0] - 1, 0, 0 ])
            Lid() {
                if($children >= 1) children(0);
                if($children >= 7) children(6);
            };
};

CaptiveNutBox("both", [ 50, 60, 30 ], countersinkScrews = true) {
    /*
    // Top
    union() {
        square([ 5, 5 ]);
        translate([ 20, 10 ])
            circle(r=3);
    };
    // Front
    union() {
        square([ 5, 5 ]);
        translate([ 20, 10 ])
            circle(r=3);
    };
    // Left
    union() {
        square([ 5, 5 ]);
        translate([ 20, 10 ])
            circle(r=3);
    };
    // Right
    union() {
        square([ 5, 5 ]);
        translate([ 20, 10 ])
            circle(r=3);
    };
    // Back
    union() {
        square([ 5, 5 ]);
        translate([ 20, 10 ])
            circle(r=3);
    };
    // Bottom
    union() {
        square([ 5, 5 ]);
        translate([ 20, 10 ])
            circle(r=3);
    };
    // Emboss
    translate([30, 20])
        text("Hi");
    translate([30, 20])
        text("Hi");
    translate([30, 20])
        text("Hi");
    translate([30, 20])
        text("Hi");
    translate([30, 20])
        text("Hi");
    translate([30, 20])
        text("Hi");
    */
};
