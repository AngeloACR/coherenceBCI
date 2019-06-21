
////////////////////////////////////////////////////
//
//    W_template.pde (ie "Widget Template")
//
//    This is a Template Widget, intended to be used as a starting point for OpenBCI Community members that want to develop their own custom widgets!
//    Good luck! If you embark on this journey, please let us know. Your contributions are valuable to everyone!
//
//    Created by: Conor Russomanno, November 2016
//
///////////////////////////////////////////////////,


class W_CoherencePlot extends Widget {

  //to see all core variables/methods of the Widget class, refer to Widget.pde
  //put your custom variables here...
  GPlot[] timeSeriesPlot = new GPlot[2];
  GPlot coherence_plot; //create an fft plot for each active channel
  GPointsArray coherence_points;  //create an array of points for each channel of data (4, 8, or 16)
  GPointsArray[] timeSeriesPoints = new GPointsArray[nchan];
  GPointsArray[] timePointsToPlot = new GPointsArray[2];
  
  int[] lineColor = {
    (int)color(129, 129, 129),
    (int)color(124, 75, 141),
    (int)color(54, 87, 158),
    (int)color(49, 113, 89),
    (int)color(221, 178, 13),
    (int)color(253, 94, 52),
    (int)color(224, 56, 45),
    (int)color(162, 82, 49),
    (int)color(129, 129, 129),
    (int)color(124, 75, 141),
    (int)color(54, 87, 158),
    (int)color(49, 113, 89),
    (int)color(221, 178, 13),
    (int)color(253, 94, 52),
    (int)color(224, 56, 45),
    (int)color(162, 82, 49)
  };
  int colorSelected = 0;

  float xF, yF, wF, hF;
  float ts_padding;
  float ts_x, ts_y, ts_h, ts_w; //values for actual time series chart (rectangle encompassing all channelBars)
  float plotBottomWell;
  int channelBarHeight;

  int[] xLimOptions = {5, 10, 15, 20};
  int[] yLimOptions = {50, 100, 200, 400, 1000, 10000};

  int xLim = xLimOptions[2];  //maximum value of x axis ... in this case 5 s, 10 s, 15 s, 20 s
  int xMax = xLimOptions[xLimOptions.length-1];   //maximum possible time
  
  int timeSeriesYLim = yLimOptions[0];
  int coherenceYLim = 1;  //maximum value of y axis ... 1

  int nPoints =  xLim * (int)getSampleRateSafe();
  int maxNPoints = xLimOptions[xLimOptions.length-1] * (int)getSampleRateSafe();
  
  float[][] timePointsTemp = new float[nchan][maxNPoints]; 
  float[] coherencePointsTemp = new float[maxNPoints]; 
  float timeBetweenPoints = (float)xLim / (float)nPoints;
  float[] time = new float[nPoints];

  FFT fftChannelA;
  FFT fftChannelB;

  int channelA = 0;
  int channelB = 1;
  
  String[] channelSelection = new String[nchan];

  W_CoherencePlot(PApplet _parent){
    super(_parent); //calls the parent CONSTRUCTOR method of Widget (DON'T REMOVE)

    xF = float(x); //float(int( ... is a shortcut for rounding the float down... so that it doesn't creep into the 1px margin
    yF = float(y);
    wF = float(w);
    hF = float(h);

    plotBottomWell = 45.0; //this appears to be an arbitrary vertical space adds GPlot leaves at bottom, I derived it through trial and error
    ts_padding = 10.0;
    ts_x = xF + ts_padding;
    ts_y = yF + (ts_padding);
    ts_w = wF - ts_padding*2;
    ts_h = hF - plotBottomWell - (ts_padding*2);
    channelBarHeight = int(ts_h/4);

    for (int i = 0; i < nchan; i++) { 
      int temp = i+1;
      channelSelection[i] = "Chan " + temp;
    }

    //This is the protocol for setting up dropdowns.
    //You just need to make sure the "id" (the 1st String) has the same name as the corresponding function

    addDropdown("timeVertScale", "Vert Scale", Arrays.asList("50 uV", "100 uV", "200 uV", "400 uV", "1000 uV", "10000 uV"), 0);    
    addDropdown("CMaxTime", "Max Time", Arrays.asList("5 s", "10 s", "15 s", "20 s"), 2);
    addDropdown("channelASelect", "Channel A", Arrays.asList(channelSelection), 0);
    addDropdown("channelBSelect", "Channel B", Arrays.asList(channelSelection), 1);

    for (int i = 0; i < nPoints; i++) { 
      time[i] = -(float)xLim + (float)i*timeBetweenPoints;
    }

    for (int i = 0; i < maxNPoints; i++) { 
      coherencePointsTemp[i] = 0f;
    }

    initializePlots(_parent);
 }

   void initializePlots(PApplet _parent) {

   //Setup points for time series point arrays
    
    timePointsToPlot[0] = new GPointsArray(nPoints);
    timePointsToPlot[1] = new GPointsArray(nPoints);
    
    for (int j = 0; j < nPoints; j++) {
      float filt_uV_value = 0.0; //0.0 for all points to start
      GPoint tempPoint = new GPoint(time[j], filt_uV_value);
      timePointsToPlot[0].set(j, tempPoint);
      timePointsToPlot[1].set(j, tempPoint);
   }
   


   //setup GPlot for timeSeries
    for (int i = 0; i < timeSeriesPlot.length; i++) {
      int timeBarY = int(ts_y) + i*(channelBarHeight);
      
      timeSeriesPlot[i] =  new GPlot(_parent); //based on container dimensions
      
      timeSeriesPlot[i].setPos(ts_x, timeBarY);
      timeSeriesPlot[i].setDim(int(ts_w), channelBarHeight);

      if(i == 0){
        timeSeriesPlot[i].getYAxis().setAxisLabelText("Channel A");
      } else{
        timeSeriesPlot[i].getYAxis().setAxisLabelText("Channel B");
      }

      timeSeriesPlot[i].setMar(60, 50, 0f, 0f); //{ bot=60, left=70, top=40, right=30 } by default
    
      
      timeSeriesPlot[i].setYLim(-50,50);
      timeSeriesPlot[i].getYAxis().setNTicks(0);
      
      timeSeriesPlot[i].setXLim(-xLim, 0);
      timeSeriesPlot[i].getXAxis().setNTicks(xLim);      
      
      timeSeriesPlot[i].setPointSize(2);
      timeSeriesPlot[i].setPointColor(0);
      timeSeriesPlot[i].setPoints(timePointsToPlot[i]);
    }


    //setup points of coherence point arrays
    coherence_points = new GPointsArray(nPoints);

    //fill coherence point arrays
    for (int i = 0; i < nPoints; i++) { 
      GPoint temp = new GPoint(10*time[i], 0);
      coherence_points.set(i, temp);
    }

    //setup GPlot for Coherence
    int coherenceBarY = int(ts_y) + 2*(channelBarHeight);
    coherence_plot =  new GPlot(_parent); //based on container dimensions

    coherence_plot.setPos(ts_x, coherenceBarY);
    coherence_plot.setDim(int(ts_w), 2*channelBarHeight);
    
    coherence_plot.getXAxis().setAxisLabelText("Time (s)");
    coherence_plot.getYAxis().setAxisLabelText("Coherence");
    coherence_plot.setMar(60, 50, 0f, 0f); //{ bot=60, left=70, top=40, right=30 } by default

    coherence_plot.setYLim(0, coherenceYLim);
    coherence_plot.getYAxis().setNTicks(5);  //sets the number of axis divisions...
    
    coherence_plot.setXLim(-xLim, 0);
    coherence_plot.getXAxis().setNTicks(xLim);  
    coherence_plot.getYAxis().setDrawTickLabels(true);
    
    coherence_plot.setPointSize(2);
    coherence_plot.setPointColor(0);



    //map fft point arrays to fft plots
    coherence_plot.setPoints(coherence_points);

  }

  void update(){
    if(isRunning){
      super.update(); //calls the parent update() method of Widget (DON'T REMOVE)

    for (int i = 0; i < nchan; i++) {
      for (int j = 0; j < nchan; j++) {
        float cTemp = getCoherence(fftBuff[i], fftBuff[j], 0, 255);
        appendAndShift(coherencePoints[i][j], cTemp);
      } 
    }

      for (int i = 0; i < nchan; i++){
        float temp = timePointsTemp[i][dataBuffY_filtY_uV[i].length-1];
        for (int j = dataBuffY_filtY_uV[i].length; j < maxNPoints; j++) {  //loop through time domain data, and store into points array
          float aux = timePointsTemp[i][j];
          timePointsTemp[i][j] = temp;
          temp = aux;
        }
        for (int j = 0; j < dataBuffY_filtY_uV[i].length; j++) {
          timePointsTemp[i][j] = dataBuffY_filtY_uV[i][dataBuffY_filtY_uV[i].length-1-j];
        }
      }

      //Setup of the points array
      float temp = coherencePointsTemp[0];
      for (int i = 1; i < maxNPoints; i++) {  //loop through time domain data, and store into points array
        float aux = coherencePointsTemp[i];
        coherencePointsTemp[i] = temp;
        temp = aux;
      }

      fftChannelA = fftBuff[channelA];
      fftChannelB = fftBuff[channelB];

      //coherencePointsTemp[0] = getCoherence(fftChannelA, fftChannelB, 0, 50);
      for (int j = 0; j < coherencePoints[channelA][channelB].length; j++) {
        coherencePointsTemp[j] = coherencePoints[channelA][channelB][coherencePoints[channelA][channelB].length-1-j];
      }



      updatePlotPoints();
    }
  }

  void draw(){
    super.draw(); //calls the parent draw() method of Widget (DON'T REMOVE)

    //put your code here... //remember to refer to x,y,w,h which are the positioning variables of the Widget class
    pushStyle();
    noStroke();

    for (int i = 0; i < timeSeriesPlot.length; i++) {
      timeSeriesPlot[i].beginDraw();
      timeSeriesPlot[i].drawBackground();
      timeSeriesPlot[i].drawBox();
      timeSeriesPlot[i].drawYAxis();
      timeSeriesPlot[i].drawGridLines(0);

      timeSeriesPlot[i].setLineColor(lineColor[(colorSelected+i)%16]);
      timeSeriesPlot[i].setPoints(timePointsToPlot[i]);
      timeSeriesPlot[i].drawLines();
      timeSeriesPlot[i].endDraw();

    }
    
    //draw Coherence Graph
    coherence_plot.beginDraw();
    coherence_plot.drawBackground();
    coherence_plot.drawBox();
    coherence_plot.drawXAxis();
    coherence_plot.drawYAxis();
    //coherence_plot.drawTopAxis();
    //coherence_plot.drawRightAxis();
    //coherence_plot.drawTitle();
    coherence_plot.drawGridLines(2);

    coherence_plot.setLineColor(lineColor[colorSelected]);
    coherence_plot.setPoints(coherence_points);
    coherence_plot.drawLines();
    coherence_plot.endDraw();

    fill(200, 200, 200);
    rect(x, y - navHeight, w, navHeight); //button bar

    popStyle();

  }

  void screenResized(){
    super.screenResized(); //calls the parent screenResized() method of Widget (DON'T REMOVE)

    //put your code here...
    
    xF = float(x); //float(int( ... is a shortcut for rounding the float down... so that it doesn't creep into the 1px margin
    yF = float(y);
    wF = float(w);
    hF = float(h);

    plotBottomWell = 45.0; //this appears to be an arbitrary vertical space adds GPlot leaves at bottom, I derived it through trial and error
    ts_padding = 10.0;
    ts_x = xF + ts_padding;
    ts_y = yF + (ts_padding);
    ts_w = wF - ts_padding*2;
    ts_h = hF - plotBottomWell - (ts_padding*2);
    channelBarHeight = int(ts_h/4);

    for (int i = 0; i < timeSeriesPlot.length; i++) {
      int timeBarY = int(ts_y) + i*(channelBarHeight);
      
      timeSeriesPlot[i].setPos(ts_x, timeBarY);
      timeSeriesPlot[i].setOuterDim(int(ts_w), channelBarHeight);
    }

    int coherenceBarY = int(ts_y) + 2*(channelBarHeight);

    coherence_plot.setPos(ts_x, coherenceBarY);//update position
    coherence_plot.setOuterDim(int(ts_w), 2*channelBarHeight);//update dimensions

  }

  void mousePressed(){
    super.mousePressed(); //calls the parent mousePressed() method of Widget (DON'T REMOVE)

    //put your code here...

  }

  void mouseReleased(){
    super.mouseReleased(); //calls the parent mouseReleased() method of Widget (DON'T REMOVE)

    //put your code here...

  }

  void updatePlotPoints(){

        for (int j = 0; j < nPoints; j++) {
          GPoint tempPointA = new GPoint(time[j], timePointsTemp[channelA][nPoints-1-j]);
          GPoint tempPointB = new GPoint(time[j], timePointsTemp[channelB][nPoints-1-j]);
          GPoint cTemp = new GPoint(10*time[j], coherencePointsTemp[nPoints-1-j]);
        
          timePointsToPlot[0].set(j, tempPointA);
          timePointsToPlot[1].set(j, tempPointB);
          coherence_points.set(j, cTemp);
          
        }


    for (int i = 0; i < timeSeriesPlot.length; i++) {
      timeSeriesPlot[i].setPoints(timePointsToPlot[i]);
    }

    coherence_plot.setPoints(coherence_points);
  }

  void adjustXAxis(int n){

    xLim = xLimOptions[n];
    timeSeriesPlot[0].setXLim(-xLim, 0);
    timeSeriesPlot[1].setXLim(-xLim, 0);
    coherence_plot.setXLim(-xLim, 0); //update the xLim of the coherence_plot
    
    nPoints =  xLim * (int)getSampleRateSafe();
    timeBetweenPoints = (float)xLim / (float)nPoints;

    time = new float[nPoints];

    for (int i = 0; i < nPoints; i++) { 
      time[i] = -(float)xLim + (float)i*timeBetweenPoints;
    }


    timePointsToPlot[0] = new GPointsArray(nPoints);
    timePointsToPlot[1] = new GPointsArray(nPoints);

    coherence_points = new GPointsArray(nPoints);

    if(xLim > 1){
      timeSeriesPlot[0].getXAxis().setNTicks(xLim);  //sets the number of axis divisions...
      timeSeriesPlot[1].getXAxis().setNTicks(xLim);  //sets the number of axis divisions...
      coherence_plot.getXAxis().setNTicks(xLim);  //sets the number of axis divisions...
    }else{
      timeSeriesPlot[0].getXAxis().setNTicks(10);  //sets the number of axis divisions...
      timeSeriesPlot[1].getXAxis().setNTicks(10);  //sets the number of axis divisions...
      coherence_plot.getXAxis().setNTicks(10);
    }
  
      updatePlotPoints();
  
  }
  
}

float getCoherence(FFT A, FFT B, int indexRangeStart, int indexRangeEnd) {
    float SAA = getPowerSpectrum(A, indexRangeStart, indexRangeEnd);
    float SBB = getPowerSpectrum(B, indexRangeStart, indexRangeEnd);
    Complex SAB = getCrossPowerSpectrum(A, B, indexRangeStart, indexRangeEnd);
    float SABMagnitude = getMagnitude(SAB.getReal(), SAB.getImag());
    float coherence = pow(SABMagnitude, 2) / (SAA * SBB);
    return coherence;
}

float getMagnitude(float realPart, float imaginaryPart) {
    float a = sqrt(pow(realPart, 2) + pow(imaginaryPart, 2));
    return a;
}

float getPowerSpectrum(FFT A, int indexRangeStart, int indexRangeEnd) {
  int n = indexRangeEnd - indexRangeStart + 1;
  float powerSpectrum = 0;
  for (int i = indexRangeStart; i <= indexRangeEnd; i++)
  {
    Complex normal = new Complex(A.getSpectrumReal()[i], A.getSpectrumImaginary()[i]);
    Complex conjugate = new Complex(normal.getReal(), normal.getImag() * -1);
    powerSpectrum += normal.multi(conjugate).getReal();
  }
  powerSpectrum /= pow(n,2);             //THIS COULD BE A REASON WHY YOU'RE NOT GETTING 0-1, look at the square?
  return powerSpectrum;
}

Complex getCrossPowerSpectrum(FFT A, FFT B, int indexRangeStart, int indexRangeEnd) {
  int n = indexRangeEnd - indexRangeStart + 1;
  Complex crossPowerSpectrum = new Complex(0,0);
  for (int i = indexRangeStart; i <= indexRangeEnd; i++)
  {
    Complex BNormal = new Complex(B.getSpectrumReal()[i], B.getSpectrumImaginary()[i]);
    Complex AConjugate = new Complex(A.getSpectrumReal()[i], A.getSpectrumImaginary()[i] * -1);
    Complex tempComplex = BNormal.multi(AConjugate);
    crossPowerSpectrum.setReal(crossPowerSpectrum.getReal() + tempComplex.getReal());
    crossPowerSpectrum.setImag(crossPowerSpectrum.getImag() + tempComplex.getImag());
  }
  crossPowerSpectrum.setReal(crossPowerSpectrum.getReal() / pow(n,2));  //THIS COULD BE A REASON WHY YOU'RE NOT GETTING 0-1, look at the square?
  crossPowerSpectrum.setImag(crossPowerSpectrum.getImag() / pow(n,2));
  return crossPowerSpectrum;
}


//These functions need to be global! These functions are activated when an item from the corresponding dropdown is selected
//triggered when there is an event in the MaxFreq. Dropdown

void CMaxTime(int n) {
  w_coherencePlot.adjustXAxis(n);
  closeAllDropdowns();
}

void channelASelect(int n) {
  w_coherencePlot.channelA = n;
  w_coherencePlot.colorSelected += 1;
  if(w_coherencePlot.colorSelected == 16){
    w_coherencePlot.colorSelected = 0;
  }
  closeAllDropdowns();
}

void channelBSelect(int n) {
  w_coherencePlot.channelB = n;
  w_coherencePlot.colorSelected += 1;
  if(w_coherencePlot.colorSelected == 16){
    w_coherencePlot.colorSelected = 0;
  }
  closeAllDropdowns();
}

void timeVertScale(int n){
  int timeSeriesYLim = w_coherencePlot.yLimOptions[n];
  w_coherencePlot.timeSeriesPlot[0].setYLim(-timeSeriesYLim, timeSeriesYLim);
  w_coherencePlot.timeSeriesPlot[1].setYLim(-timeSeriesYLim, timeSeriesYLim);
}



 //And create a class Complex
  
 class Complex {
  float real;
  float imag; 
  
  public Complex(float real, float imag)
  {
    this.real = real; 
    this.imag = imag; 
  }
  
  public Complex multi(Complex c)
  {
    float real = this.real * c.real - this.imag * c.imag;
    float imag = this.real * c.imag + this.imag * c.real;
    return new Complex(real, imag);
  }
  
  public void setReal(float n)
  {
    real = n;
  }
  
  public void setImag(float n)
  {
    imag = n;
  }
  
  public float getReal()
  {
    return real;
  }
  
  public float getImag()
  {
    return imag;
  }
}
