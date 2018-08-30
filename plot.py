import random
import time
import json
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.tri as tri
import shapely.geometry as shp
import math
from matplotlib.mlab import griddata
from matplotlib.colors import LinearSegmentedColormap
from shapely.geometry import Polygon, MultiPolygon
from geopandas import GeoDataFrame
import geopandas as gpd


# global settings
pointsPerDegree = 5
isByClaim = 1

# load in airport data from R processing
airports_df = pd.read_csv("./processed/claimData.csv")
airports_df.dropna()
airports_df = airports_df.loc[airports_df['count']>250 ,:]
airports_df.to_csv('./viz/data/airports.csv', columns=['Airport.Code','Name','Lat','Lon'], index_label='id')


# define category of interest
winnerStats = []

for idx in range(8,33):
    print('--')
    print(idx)
    categoryOfInterest = airports_df.columns[idx]
    print(categoryOfInterest)

    airports_df['target'] = airports_df[categoryOfInterest]/(airports_df['totalEnplaned'])
    gobalAvgValue = sum(airports_df[categoryOfInterest])/sum(airports_df['totalEnplaned'])
    if (isByClaim):
        airports_df['target'] = airports_df[categoryOfInterest]/(airports_df['count'])
        gobalAvgValue = sum(airports_df[categoryOfInterest])/sum(airports_df['count'])


    #find max in this category
    maxRow = airports_df['target'].idxmax()
    thisWinnerData = airports_df.ix[maxRow]

    thisWinner = {'idx':  idx-8,
                  'val':  100.0*(thisWinnerData['target']-gobalAvgValue)/gobalAvgValue,
                  'globalAvgVal':  gobalAvgValue,
                  'winnerVal':     thisWinnerData['target'],
                  'Catg': categoryOfInterest,
                  'Code': thisWinnerData['Airport.Code'],
                  'Name': thisWinnerData['Name'],
                  'Lat':  thisWinnerData['Lat'],
                  'Lon':  thisWinnerData['Lon']}
    winnerStats.append(thisWinner)


    # Create grid values first.
    xi = np.linspace(-180, -65, 115*pointsPerDegree+1)
    yi = np.linspace(10, 75, 65*pointsPerDegree+1)
    Xi, Yi = np.meshgrid(xi, yi)


    # we'll bbe doing a weighted average so lets define the weights
    global myTrainingWeights
    myTrainingWeights = np.array(airports_df['meanEnplaned'])

    # and our "training" data for our interpolation
    trainingX = np.column_stack((airports_df['Lon'], airports_df['Lat']))
    trainingY = np.array(airports_df['target'])


    # actually perform the interpolation on our grid of points
    N_neighbors_min = 40
    R_max = 250
    def greatCircleDistance(lon1,lat1,lon2,lat2):
        deg2rad = math.pi/180.0
        lon1r = lon1*deg2rad
        lat1r = lat1*deg2rad
        lon2r = lon2*deg2rad
        lat2r = lat2*deg2rad
        if (abs(lon1-lon2)+abs(lat1-lat2)>0.0000001):
            centralAngle = math.acos( math.sin(lat1r)*math.sin(lat2r) + math.cos(lat1r)*math.cos(lat2r)*math.cos(lon2r-lon1r)  )
        else:
            centralAngle = 0
        return centralAngle*6378

    predCoords = np.column_stack((Xi.reshape(-1,1),Yi.reshape(-1,1)))
    N_points = predCoords.shape[0]
    N_training = trainingX.shape[0]
    predVals = np.zeros(N_points)

    for ii in range(N_points):
        thisPoint = predCoords[ii]

        distToTrainings = np.zeros(N_training)
        for jj in range(N_training):
            thisTraining = trainingX[jj]
            distToTrainings[jj] = greatCircleDistance(thisPoint[0],thisPoint[1],thisTraining[0],thisTraining[1])

        # weighted avg of all within R_max (unless < N_neighbors_min... in which case jsut weight nearest N )
        weightQuotients = myTrainingWeights / (distToTrainings**2)
        # which ones to use?
        # weighted avg of all within R_max (unless < N_neighbors_min... in which case jsut weight nearest N )
        withinRad = distToTrainings<R_max
        NumWithinRad = sum(withinRad)
        if (NumWithinRad >= N_neighbors_min):
            # weighted avg of all within R_max
            isUsed = withinRad
        else:
            # use the nearest N
            sortedDists = np.sort(distToTrainings)
            nthDist = sortedDists[N_neighbors_min]
            isUsed = 1.00*(distToTrainings<(0.999999*nthDist))

        myWeights = weightQuotients*isUsed
        #if (sum(myWeights)<1):
            #print(sortedDists)10
        predVals[ii] = np.average(trainingY, weights=myWeights)

    predVals.reshape(Xi.shape)
    zi = predVals.reshape(Xi.shape)




    # prepare zi for plotting
    zi_diff = ((zi-gobalAvgValue)/gobalAvgValue)



    # clip it at +/- 100% to maintain consistent viz across categories
    maxDiff = 100.0
    zi_diff_clipped = np.minimum(np.maximum(zi_diff,-maxDiff/100.0),maxDiff/100.0)
    myLevels = np.linspace(-maxDiff/100.0, maxDiff/100.0, 101)



    # get those sweet sweet contours
    figure = plt.figure()
    ax = figure.add_subplot(111)
    mycontour = plt.contourf(xi, yi, zi_diff_clipped, myLevels, cmap=plt.cm.jet)
    def collec_to_gdf(collec_poly):
        """Transform a `matplotlib.contour.QuadContourSet` to a GeoDataFrame"""
        polygons, colors, levels = [], [], []
        for i, polygon in enumerate(collec_poly.collections):
            mpoly = []
            for path in polygon.get_paths():
                try:
                    path.should_simplify = False
                    poly = path.to_polygons()
                    # Each polygon should contain an exterior ring + maybe hole(s):
                    exterior, holes = [], []
                    if len(poly) > 0 and len(poly[0]) > 3:
                        # The first of the list is the exterior ring :
                        exterior = poly[0]
                        # Other(s) are hole(s):
                        if len(poly) > 1:
                            holes = [h for h in poly[1:] if len(h) > 3]
                    mpoly.append(Polygon(exterior, holes))
                except:
                    print('Warning: Geometry error when making polygon #{}'
                          .format(i))
            if len(mpoly) > 1:
                mpoly = MultiPolygon(mpoly)
                polygons.append(mpoly)
                colors.append(polygon.get_facecolor().tolist()[0])
                levels.append(myLevels[i]*100.0)
            elif len(mpoly) == 1:
                polygons.append(mpoly[0])
                colors.append(polygon.get_facecolor().tolist()[0])
                levels.append(myLevels[i]*100.0)
        return GeoDataFrame(
            geometry=polygons,
            data={'RGBA': colors, 'levels':levels},
            crs={'init': 'epsg:4326'})

    contour_df = collec_to_gdf(mycontour)
    plt.close(figure)


    # but all my contours are on the giant rectangle - need to crop them to fit snugly in USA
    # load USA
    us_df = gpd.read_file('us-states.json')
    usaPoly = us_df.buffer(0).unary_union


    # crop 'em
    N_shapes = len(contour_df.geometry)
    for ii in range(N_shapes):
        oldGeom = contour_df.geometry[ii]
        newGeom = oldGeom.intersection(usaPoly)
        contour_df.geometry[ii] = newGeom


    # write the contour data
    geojsonfilepath = "./viz/data/categoryContours/category_"+str(idx-8)+".geojson"
    if (isByClaim):
        geojsonfilepath = "./viz/data/categoryContours/category_"+str(idx-8)+"_byClaim.geojson"
    f = open(geojsonfilepath, "w")
    f.write(contour_df.to_json())
    f.close()



# write the winners per category
winnersfilepath = "./viz/data/winners.json"
if (isByClaim):
    winnersfilepath = "./viz/data/winners_byClaim.json"
with open(winnersfilepath, 'w') as outfile:
        json.dump(winnerStats, outfile)
