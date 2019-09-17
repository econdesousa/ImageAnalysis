**Goal**

* Segment Fibers and then count number of cells over them.
  * Fiber Segmentation faces one main problem, the histogram distribution is skewed to the left.
  * Counting cells is based on find maxima function thus is sensitive to max tolerance parameter.



**Usage:**

* First run script FilamentSegmentation_v1.1.ijm
  * This will output a folder with B&C enhaced version of the original image (not to be used elsewhere - just for visualization) and a roi file for each image
* The run CountCells_v3.ijm
  * input should be Noise Tolerance (tipically a value between 1000 and 2000, DEAFULT=1500).
  * the folder with the roi (no prblem to keep the tif files there)
  * the working images (the same given to FilamentSegmentation_v1.1.ijm)
  * an output folder



**DISCLAIMER**

Not working perfectly in the dataset available. The original image files are huge and cannot fit the github size criterium without being heavily cropped and therefore are too small causing the automatic threshold to detect background as belonging to the fibers.

