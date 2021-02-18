To perform 3D Nucelei Segmentation I usually 

1. go to the Pixel Classification workflow and train a model
2. applyed the model to a new image and save the probability map
3. go to the Object Classification workflow
fine-tuned the hysteresis threshold values
and apply the classifier and export the object identities
