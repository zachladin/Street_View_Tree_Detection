# Script for running yolo
# myDir = '/Users/zach/Dropbox (ZachTeam)/Projects/Street_View_Shiny_App/TOH_yolo'
# newImage = "Ailanthus.4"

# set working directory
def yolo_in_R(myDir, imageName, threshold):
        
        myDir = myDir
        imageName = imageName

        import os
        os.chdir(myDir)

        # import libraries
        from darkflow.net.build import TFNet
        import cv2
        import matplotlib.pyplot as plt
        import matplotlib.image as mpimg

        # options for tiny-yolo-voc-1class (trained model)
        options = {
                'model': 'cfg/tiny-yolo-voc-1class_toh.cfg',
                'load': 1000,
                'threshold': threshold,
                'gpu': 1.0
        }

        tfnet = TFNet(options)

        # create image object
        # global img
        # img = None
        img = cv2.imread("Downloaded_images/" + imageName + ".jpg", cv2.IMREAD_COLOR)
        # img = cv2.imread("sample_img/sample_toh.jpg", cv2.IMREAD_COLOR)
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

        # plt.imshow(img)
        # plt.show()

        img
        img.shape

        # predict objects in image
        # result = None
        result = tfnet.return_predict(img)
        result

        # set up bounding boxes
        tl = (int(result[0]['topleft']['x']), int(result[0]['topleft']['y']))
        br = (int(result[0]['bottomright']['x']), int(result[0]['bottomright']['y']))
        label = result[0]['label']

        # open CV commands
        img = cv2.rectangle(img, tl, br, (0,255,0), 5)
        # add label to bounding box
        img = cv2.putText(img, label, tl, cv2.FONT_HERSHEY_COMPLEX, 1, (0,253,0), 2)

        # display image with bounding box
        # plt.imshow(img)
        # plt.show()

        # save image
        mpimg.imsave("Labeled_images/" + imageName + "_labeled.jpg", img)
