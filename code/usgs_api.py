# =============================================================================
#  USGS/EROS Inventory Service Example
#  Python - JSON API
# 
#  Script Last Modified: 6/17/2020
#  Note: This example does not include any error handling!
#        Any request can throw an error, which can be found in the errorCode proprty of
#        the response (errorCode, errorMessage, and data properies are included in all responses).
#        These types of checks could be done by writing a wrapper similiar to the sendRequest function below
#  Usage: python download_data.py -u username -p password
# =============================================================================

import json
import requests
import sys
import time
import argparse

# send http request
def sendRequest(url, data, apiKey = None):  
    #json_data = json.dumps(data)
    
    if apiKey == None:
        response = requests.post(url, json=data)
    else:
        headers = {'X-Auth-Token': apiKey}              
        response = requests.post(url, json=data, headers = headers) 

    print(response)   
    
    try:
      httpStatusCode = response.status_code 
      if response == None:
          print("No output from service")
          sys.exit()
      output = json.loads(response.text)	
      if output['errorCode'] != None:
          print(output['errorCode'], "- ", output['errorMessage'])
          sys.exit()
      if  httpStatusCode == 404:
          print("404 Not Found")
          sys.exit()
      elif httpStatusCode == 401: 
          print("401 Unauthorized")
          sys.exit()
      elif httpStatusCode == 400:
          print("Error Code", httpStatusCode)
          sys.exit()
    except Exception as e: 
          response.close()
          print(e)
          sys.exit()
    response.close()
    
    return output['data']

# interact with API
def searchScenes(username,
                 password, 
                 datasetAlias = None, 
                 spatialFilter = None,
                 acquisitionFilter = None,
                 cloudCoverFilter = None):

    if datasetAlias is None:
        datasetAlias = "landsat_ard_tile_c2"

    if spatialFilter is None:

        spatialFilter = {
           "filterType": "mbr",
           "lowerLeft": {
                   "latitude": 39.92817,
                   "longitude": -74.66431
           },
           "upperRight": {
                   "latitude": 41.54334,
                   "longitude": -72.50449
           }
        }
    
    if acquisitionFilter is None:
        acquisitionFilter = {"end": "2018-01-10", "start": "2023-01-01" }  

    if cloudCoverFilter is None:
        cloudCoverFilter = {
            "cloudCoverFilter": {
                "max": 3,
                "min": 0,
                "includeUnknown": False
            }
        }   

    serviceUrl = "https://m2m.cr.usgs.gov/api/api/json/stable/"

        
    print("\nRunning ...\n")
    
    
    # login
    payload = {
        'username' : username, 
        'password' : password
        }
    
    apiKey = sendRequest(serviceUrl + "login", payload)
    
    print("API Key: " + apiKey + "\n")
        
    payload = {
        'datasetName' : datasetAlias, 
        'sceneFilter' : {
            'spatialFilter' : spatialFilter,
            'acquisitionFilter' : acquisitionFilter,
            'cloudCoverFilter': cloudCoverFilter
            }
        }
    
    # Now I need to run a scene search to find data to download
    print("Searching scenes...\n\n")   
    
    scenes = sendRequest(serviceUrl + "scene-search", payload, apiKey)

    # Did we find anything?
    if scenes['recordsReturned'] > 0:

        # Aggregate a list of scene ids
        sceneIds = []
        for result in scenes['results']:
            # Add this scene to the list I would like to download
            sceneIds.append(result['entityId'])
        
        # Find the download options for these scenes
        # NOTE :: Remember the scene list cannot exceed 50,000 items!
        payload = {'datasetName' : datasetAlias, 'entityIds' : sceneIds}
                            
        downloadOptions = sendRequest(serviceUrl + "download-options", payload, apiKey)
    
        # Aggregate a list of available products
        downloads = []
        for product in downloadOptions:
                # Make sure the product is available for this scene
                if product['available'] == True:
                        downloads.append({
                            'entityId' : product['entityId'],
                            'productId' : product['id']
                            })
                        
        # Did we find products?
        if downloads:
            
            requestedDownloadsCount = len(downloads)
            # set a label for the download request
            label = "download-sample"
            payload = {'downloads' : downloads, 'label' : label}
            # Call the download to get the direct download urls
            requestResults = sendRequest(serviceUrl + "download-request", payload, apiKey)          
                            
            # PreparingDownloads has a valid link that can be used but data may not be immediately available
            # Call the download-retrieve method to get download that is available for immediate download
            if requestResults['preparingDownloads'] != None and len(requestResults['preparingDownloads']) > 0:
                
                payload = {'label' : label}
                moreDownloadUrls = sendRequest(serviceUrl + "download-retrieve", payload, apiKey)
                
                downloadIds = []  
                
                for download in moreDownloadUrls['available']:
                    if str(download['downloadId']) in requestResults['newRecords'] or str(download['downloadId']) in requestResults['duplicateProducts']:
                        downloadIds.append(download['downloadId'])
                        print("DOWNLOAD: " + download['url'])
                    
                for download in moreDownloadUrls['requested']:
                    if str(download['downloadId']) in requestResults['newRecords'] or str(download['downloadId']) in requestResults['duplicateProducts']:
                        downloadIds.append(download['downloadId'])
                        print("DOWNLOAD: " + download['url'])
                    
                # Didn't get all of the reuested downloads, call the download-retrieve method again probably after 30 seconds
                while len(downloadIds) < (requestedDownloadsCount - len(requestResults['failed'])): 
                    preparingDownloads = requestedDownloadsCount - len(downloadIds) - len(requestResults['failed'])
                    print("\n", preparingDownloads, "downloads are not available. Waiting for 30 seconds.\n")
                    time.sleep(30)
                    print("Trying to retrieve data\n")
                    moreDownloadUrls = sendRequest(serviceUrl + "download-retrieve", payload, apiKey)
                    for download in moreDownloadUrls['available']:                            
                        if download['downloadId'] not in downloadIds and (str(download['downloadId']) in requestResults['newRecords'] or str(download['downloadId']) in requestResults['duplicateProducts']):
                            downloadIds.append(download['downloadId'])
                            print("DOWNLOAD: " + download['url']) 
                        
            else:
                # Get all available downloads
                for download in requestResults['availableDownloads']:
                    # TODO :: Implement a downloading routine
                    print("DOWNLOAD: " + download['url'])   
            print("\nAll downloads are available to download.\n")

        else:
            print("X results were found but none available for download.")
    else:
        print("Search found no results.\n")
        print(scenes)
            
    # Logout so the API Key cannot be used anymore
    endpoint = "logout"  
    if sendRequest(serviceUrl + endpoint, None, apiKey) == None:        
        print("Logged Out\n\n")
    else:
        print("Logout Failed\n\n")            
    

if __name__ == '__main__': 
    #NOTE :: Passing credentials over a command line arguement is not considered secure
    #        and is used only for the purpose of being example - credential parameters
    #        should be gathered in a more secure way for production usage
    #Define the command line arguements
    
    # user input    
    parser = argparse.ArgumentParser()
    parser.add_argument('-u', '--username', required=True, help='Username')
    parser.add_argument('-p', '--password', required=True, help='Password')
    
    args = parser.parse_args()
    
    username = args.username
    password = args.password    

    searchScenes(username, password) 
