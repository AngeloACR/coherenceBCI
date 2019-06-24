//<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>// //<>//
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

  float coherencePoints[][];
  float coherenceFreqPoints[][];
  Coherence[] coherence = new Coherence[nchan/2];

  int cFilter = 0;

  long currentTime = 0;
  long prevTime = 0;

  //to see all core variables/methods of the Widget class, refer to Widget.pde
  //put your custom variables here...
  GPlot[] timeSeriesPlot = new GPlot[2];
  GPlot coherencePlot; //create an fft plot for each active channel
//  GPlot coherenceFreqPlot; //create an fft plot for each active channel
//  GPointsArray coherencePointsToFreqPlot;  //create an array of points for each channel of data (4, 8, or 16)
  GPointsArray coherencePointsToPlot;  //create an array of points for each channel of data (4, 8, or 16)
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

  //int[] xLimOptions = {1, 3, 5, 7};
  int[] xLimOptions = {7};
  int[] yLimOptions = {50, 100, 200, 400, 1000, 10000};

 // int xLim = xLimOptions[2];  //maximum value of x axis ... in this case 5 s, 10 s, 15 s, 20 s
  int xLim = xLimOptions[0];  //maximum value of x axis ... in this case 5 s, 10 s, 15 s, 20 s
  int xMax = xLimOptions[xLimOptions.length-1];   //maximum possible time

  int[] xFreqLimOptions = {20, 40, 60, 100, 120, 250, 500, 800};

  int xFreqLim = xFreqLimOptions[5];  //maximum value of x axis ... in this case 5 s, 10 s, 15 s, 20 s
  int xFreqMax = xFreqLimOptions[xFreqLimOptions.length-1];   //maximum possible time
  int coherenceIndexLim = int(1.0*xFreqMax*(getNfftSafe()/getSampleRateSafe()));   // maxim value of FFT index

  int timeSeriesYLim = yLimOptions[0];
  int coherenceYLim = 1;  //maximum value of y axis ... 1

  int fs = (int)getSampleRateSafe();
  int nPoints =  xLim * fs;
  int nfft = getNfftSafe();

  float timeBetweenPoints = (float)xLim / (float)nPoints;
  float[] time = new float[nPoints];

  int channels = 0;

  String plotDom = "time";

  String[] channelSelection = new String[nchan/2];

  W_CoherencePlot(PApplet _parent) {
    super(_parent); //calls the parent CONSTRUCTOR method of Widget (DON'T REMOVE)

    coherencePoints = new float[nchan/2][dataBuffX.length];
    coherenceFreqPoints = new float[nchan/2][nfft/2];


    for (int i = 0; i < nchan/2; i++) { 
      coherence[i] = new Coherence(nfft, fs);
    }

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

    for (int i = 0; i < nchan/2; i++) { 
      int temp1 = 2*i+1;
      int temp2 = 2*i+2;
      channelSelection[i] = "";
      channelSelection[i] += temp1;
      channelSelection[i] += " Vs. ";
      channelSelection[i] += temp2;
    }

    //This is the protocol for setting up dropdowns.
    //You just need to make sure the "id" (the 1st String) has the same name as the corresponding function

//    addDropdown("plotDom", "Plot Type", Arrays.asList("Freq", "Time"), 1);
    addDropdown("plotDom", "Plot Type", Arrays.asList("Time"), 0);
//    addDropdown("pbFilter", "PB Filter", Arrays.asList("Theta", "Alpha 1", "Alpha 2", "Alpha", "Beta", "Gamma"), 0);
    addDropdown("pbFilter", "PB Filter", Arrays.asList("Alpha"), 0);
    addDropdown("timeVertScale", "Vert Scale", Arrays.asList("50 uV", "100 uV", "200 uV", "400 uV", "1000 uV", "10000 uV"), 0);    
//    addDropdown("CMaxTime", "Max Time", Arrays.asList("1 s", "3 s", "5 s", "7 s"), 2);
    addDropdown("CMaxTime", "Max Time", Arrays.asList("7 s"), 0);
//    addDropdown("channelsSelect", "Channels", Arrays.asList(channelSelection), 0);
    addDropdown("channelsSelect", "Channels", Arrays.asList(channelSelection[0]), 0);

    for (int i = 0; i < nPoints; i++) { 
      time[i] = -(float)xLim + (float)i*timeBetweenPoints;
    }

    initializePlots(_parent);
  }

  void initializePlots(PApplet _parent) {


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

      if (i == 0) {
        timeSeriesPlot[i].getYAxis().setAxisLabelText("Channel A");
      } else {
        timeSeriesPlot[i].getYAxis().setAxisLabelText("Channel B");
      }

      timeSeriesPlot[i].setMar(60, 50, 0f, 0f); //{ bot=60, left=70, top=40, right=30 } by default


      timeSeriesPlot[i].setYLim(-50, 50);
      timeSeriesPlot[i].getYAxis().setNTicks(0);

      timeSeriesPlot[i].setXLim(-xLim, 0);
      timeSeriesPlot[i].getXAxis().setNTicks(xLim);      

      timeSeriesPlot[i].setPointSize(2);
      timeSeriesPlot[i].setPointColor(0);
      timeSeriesPlot[i].setPoints(timePointsToPlot[i]);
    }


    //setup points of coherence point arrays
    coherencePointsToPlot = new GPointsArray(nPoints);

    //fill coherence point arrays
    for (int i = 0; i < nPoints; i++) { 
      GPoint temp = new GPoint(10*time[i], 0);
      coherencePointsToPlot.set(i, temp);
    }

    //setup GPlot for Coherence
    int coherenceBarY = int(ts_y) + 2*(channelBarHeight);
    coherencePlot =  new GPlot(_parent); //based on container dimensions

    coherencePlot.setPos(ts_x, coherenceBarY);
    coherencePlot.setDim(int(ts_w), 2*channelBarHeight);

    coherencePlot.getXAxis().setAxisLabelText("Time (s)");
    coherencePlot.getYAxis().setAxisLabelText("Coherence");
    coherencePlot.setMar(60, 50, 0f, 0f); //{ bot=60, left=70, top=40, right=30 } by default

    coherencePlot.setYLim(0, coherenceYLim);
    coherencePlot.getYAxis().setNTicks(5);  //sets the number of axis divisions...

    coherencePlot.setLineWidth(3);

    coherencePlot.setXLim(-xLim, 0);
    coherencePlot.getXAxis().setNTicks(xLim);  
    coherencePlot.getYAxis().setDrawTickLabels(true);

    coherencePlot.setPointSize(2);
    coherencePlot.setPointColor(0);

    //map fft point arrays to fft plots
    coherencePlot.setPoints(coherencePointsToPlot);

    //setup points of coherence point arrays
   /* coherencePointsToFreqPlot = new GPointsArray(coherenceIndexLim);

    //fill coherence point arrays
    for (int i = 0; i < coherenceIndexLim; i++) { 
      GPoint coherenceAtBin = new GPoint((1.0*fs/nfft)*i, 0);
      coherencePointsToFreqPlot.set(i, coherenceAtBin);
    }*/

 /*   //setup GPlot for Coherence
    coherenceFreqPlot =  new GPlot(_parent); //based on container dimensions
    coherenceFreqPlot.setPos(ts_x, coherenceBarY);
    coherenceFreqPlot.setDim(int(ts_w), 2*channelBarHeight);
    coherenceFreqPlot.getXAxis().setAxisLabelText("Frequency (Hz)");
    coherenceFreqPlot.getYAxis().setAxisLabelText("Coherence");
    coherenceFreqPlot.setMar(60, 50, 0f, 0f); //{ bot=60, left=70, top=40, right=30 } by default
    coherenceFreqPlot.setYLim(0, coherenceYLim);
    coherenceFreqPlot.getYAxis().setNTicks(5);  //sets the number of axis divisions...
    coherenceFreqPlot.setLineWidth(3);
    coherenceFreqPlot.setXLim(0, xFreqLim/2);
    coherenceFreqPlot.getYAxis().setDrawTickLabels(true);
    coherenceFreqPlot.setPointSize(2);
    coherenceFreqPlot.setPointColor(0);
    //map fft point arrays to fft plots
    coherenceFreqPlot.setPoints(coherencePointsToFreqPlot);*/
  }

  void update() {
    if (isRunning) {
      super.update(); //calls the parent update() method of Widget (DON'T REMOVE)

/*      for (int i = 0; i < nchan/2; i++) {
        coherence[i].calcCoherence(dataBuffY_uV[2*i], dataBuffY_uV[2*i+1]);
        float cTemp = coherence[i].cVal();
        appendAndShift(coherencePoints[i], cTemp);
      }*/

        coherence[0].calcCoherence(dataBuffY_uV[0], dataBuffY_uV[1]);
        float cTemp = coherence[0].cVal();
        appendAndShift(coherencePoints[0], cTemp);

      updatePlotPoints();
    }
  }

  void updatePlotPoints() {

    int channelA = 2*channels;
    int channelB = 2*channels+1;


    int a = dataBuffY_filtY_uV[channelA].length;
    int b = dataBuffY_filtY_uV[channelB].length;
    int c = coherencePoints[channels].length;

    float aTemp;
    float bTemp;
    float cTemp;
    float[] cFreqTemp = new float[nfft/2];

    for (int j = 0; j < nPoints; j++) {

      aTemp = dataBuffY_filtY_uV[channelA][a+j-nPoints];
      bTemp = dataBuffY_filtY_uV[channelB][b+j-nPoints];
      cTemp = (float)coherencePoints[channels][c+j-nPoints];  

      GPoint tempPointA = new GPoint(time[j], aTemp);
      GPoint tempPointB = new GPoint(time[j], bTemp);
      GPoint chTemp = new GPoint(10*time[j], cTemp);

      timePointsToPlot[0].set(j, tempPointA);
      timePointsToPlot[1].set(j, tempPointB);
      coherencePointsToPlot.set(j, chTemp);
    }


//    cFreqTemp = coherence[channels].getCoherence();


    currentTime = System.currentTimeMillis();

   /* if ( 1000 < currentTime - prevTime) {
      for (int j = 0; j < coherenceIndexLim; j++) {
        if ( cFreqTemp.length <= j ) {
          GPoint coherenceAtBin = new GPoint((1.0*fs/nfft)*j, 0);
          coherencePointsToFreqPlot.set(j, coherenceAtBin);
        } else {
          GPoint coherenceAtBin = new GPoint((1.0*fs/nfft)*j, cFreqTemp[j]);
          coherencePointsToFreqPlot.set(j, coherenceAtBin);
        }
      }
      prevTime = currentTime;
    }*/


    for (int i = 0; i < timeSeriesPlot.length; i++) {
      timeSeriesPlot[i].setPoints(timePointsToPlot[i]);
    }

    coherencePlot.setPoints(coherencePointsToPlot);
  }

  void draw() {
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


    switch(plotDom) {
      case("time"):
      //draw Coherence Graph
      coherencePlot.beginDraw();
      coherencePlot.drawBackground();
      coherencePlot.drawBox();
      coherencePlot.drawXAxis();
      coherencePlot.drawYAxis();
      //coherencePlot.drawTopAxis();
      //coherencePlot.drawRightAxis();
      //coherencePlot.drawTitle();
      coherencePlot.drawGridLines(2);

      coherencePlot.setLineColor(lineColor[colorSelected]);
      coherencePlot.setPoints(coherencePointsToPlot);
      coherencePlot.drawLines();
      coherencePlot.endDraw();
      break;

/*      case("freq"):
      //draw Coherence Graph
      coherenceFreqPlot.beginDraw();
      coherenceFreqPlot.drawBackground();
      coherenceFreqPlot.drawBox();
      coherenceFreqPlot.drawXAxis();
      coherenceFreqPlot.drawYAxis();
      //coherencePlot.drawTopAxis();
      //coherencePlot.drawRightAxis();
      //coherencePlot.drawTitle();
      coherenceFreqPlot.drawGridLines(2);
      coherenceFreqPlot.setLineColor(lineColor[colorSelected]);
      coherenceFreqPlot.setPoints(coherencePointsToFreqPlot);
      coherenceFreqPlot.drawLines();
      coherenceFreqPlot.endDraw();
      break;*/
    default:
      //draw Coherence Graph
      coherencePlot.beginDraw();
      coherencePlot.drawBackground();
      coherencePlot.drawBox();
      coherencePlot.drawXAxis();
      coherencePlot.drawYAxis();
      //coherencePlot.drawTopAxis();
      //coherencePlot.drawRightAxis();
      //coherencePlot.drawTitle();
      coherencePlot.drawGridLines(2);

      coherencePlot.setLineColor(lineColor[colorSelected]);
      coherencePlot.setPoints(coherencePointsToPlot);
      coherencePlot.drawLines();
      coherencePlot.endDraw();
      break;
    }

    fill(200, 200, 200);
    rect(x, y - navHeight, w, navHeight); //button bar

    popStyle();
  }

  void screenResized() {
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

    coherencePlot.setPos(ts_x, coherenceBarY);//update position
    coherencePlot.setOuterDim(int(ts_w), 2*channelBarHeight);//update dimensions

/*    coherenceFreqPlot.setPos(ts_x, coherenceBarY);//update position
    coherenceFreqPlot.setOuterDim(int(ts_w), 2*channelBarHeight);//update dimensions*/
  }

  void mousePressed() {
    super.mousePressed(); //calls the parent mousePressed() method of Widget (DON'T REMOVE)

    //put your code here...
  }

  void mouseReleased() {
    super.mouseReleased(); //calls the parent mouseReleased() method of Widget (DON'T REMOVE)

    //put your code here...
  }


  void adjustXAxis(int n) {

    xLim = xLimOptions[n];
    timeSeriesPlot[0].setXLim(-xLim, 0);
    timeSeriesPlot[1].setXLim(-xLim, 0);
    coherencePlot.setXLim(-xLim, 0); //update the xLim of the coherencePlot

    nPoints =  xLim * fs;
    timeBetweenPoints = (float)xLim / (float)nPoints;

    time = new float[nPoints];

    for (int i = 0; i < nPoints; i++) { 
      time[i] = -(float)xLim + (float)i*timeBetweenPoints;
    }


    timePointsToPlot[0] = new GPointsArray(nPoints);
    timePointsToPlot[1] = new GPointsArray(nPoints);

    coherencePointsToPlot = new GPointsArray(nPoints);

    if (xLim > 1) {
      timeSeriesPlot[0].getXAxis().setNTicks(xLim);  //sets the number of axis divisions...
      timeSeriesPlot[1].getXAxis().setNTicks(xLim);  //sets the number of axis divisions...
      coherencePlot.getXAxis().setNTicks(xLim);  //sets the number of axis divisions...
    } else {
      timeSeriesPlot[0].getXAxis().setNTicks(10);  //sets the number of axis divisions...
      timeSeriesPlot[1].getXAxis().setNTicks(10);  //sets the number of axis divisions...
      coherencePlot.getXAxis().setNTicks(10);
    }

    updatePlotPoints();
  }
}



//These functions need to be global! These functions are activated when an item from the corresponding dropdown is selected
//triggered when there is an event in the MaxFreq. Dropdown

void CMaxTime(int n) {
  w_coherencePlot.adjustXAxis(n);
  closeAllDropdowns();
}

void channelsSelect(int n) {
  w_coherencePlot.channels = n;
  w_coherencePlot.colorSelected += 1;
  if (w_coherencePlot.colorSelected == 16) {
    w_coherencePlot.colorSelected = 0;
  }
  closeAllDropdowns();
}


void timeVertScale(int n) {
  int timeSeriesYLim = w_coherencePlot.yLimOptions[n];
  w_coherencePlot.timeSeriesPlot[0].setYLim(-timeSeriesYLim, timeSeriesYLim);
  w_coherencePlot.timeSeriesPlot[1].setYLim(-timeSeriesYLim, timeSeriesYLim);
  closeAllDropdowns();
}

void pbFilter(int n) {
  w_coherencePlot.cFilter = n;
  closeAllDropdowns();
}

void plotDom(int n) {
  switch(n) {
  case 0: 
    w_coherencePlot.plotDom = "freq";
    break;
  case 1: 
    w_coherencePlot.plotDom = "time";
    break;
  default: 
    w_coherencePlot.plotDom = "time";
    break;
  }
  closeAllDropdowns();
}

class Coherence {

  private float[] fftA;
  private float[] fftB;

  private FFT chanA;
  private FFT chanB;


  private double[] a;
  private double[] b;

  private int nfft;
  private int fs;

  private float coherence;

  Coherence(int Nfft, int Fs) {

    fs=Fs;
    nfft=Nfft;

    fftA = new float[nfft];
    fftB = new float[nfft];

    chanA = new FFT(getNfftSafe(), getSampleRateSafe());
    chanB = new FFT(getNfftSafe(), getSampleRateSafe());
  }

  private void calcCoherence(float[] dataA, float[] dataB) {

    float[] dataACR = new float[dataA.length];
    float[] dataBCR = new float[dataB.length];

    float[] SAA = new float[nfft/2];
    float[] SBB = new float[nfft/2];

    float[] crossPowerReal = new float[nfft/2];
    float[] crossPowerImag = new float[nfft/2];
    float[] SAB = new float[nfft/2];

    double[] weight = new double[dataA.length];

    int nLoaded = 0;

    int n = dataA.length;

    dataACR = lrmv(dataA);
    dataBCR = lrmv(dataB);

    getCoef();
    dataACR = applyPassband(b, a, dataACR);
    dataBCR = applyPassband(b, a, dataBCR);


    for (int i = 0; i < n; i++) {
      weight[i] = 0.5*(1 - cos(2.0*PI*i/(n - 1)));
    }


    for (int i = 0; i < n; i++) {
      dataACR[i] *= weight[i];
      dataBCR[i] *= weight[i];
    }

    chanA = createFFT(chanA, dataACR, nfft, fs);
    chanB = createFFT(chanB, dataBCR, nfft, fs);

    coherence = getCoherence(chanA, chanB, 0, 255);
  }

  private float getCoherence(FFT A, FFT B, int indexRangeStart, int indexRangeEnd) {
      float SAA = getPowerSpectrum(A, indexRangeStart, indexRangeEnd);
      float SBB = getPowerSpectrum(B, indexRangeStart, indexRangeEnd);
      Complex SAB = getCrossPowerSpectrum(A, B, indexRangeStart, indexRangeEnd);
      float SABMagnitude = getMagnitude(SAB.getReal(), SAB.getImag());
      float coherence = pow(SABMagnitude, 2) / (SAA * SBB);
      return coherence;
  }

  private float getMagnitude(float realPart, float imaginaryPart) {
      float a = sqrt(pow(realPart, 2) + pow(imaginaryPart, 2));
      return a;
  }

  private float getPowerSpectrum(FFT A, int indexRangeStart, int indexRangeEnd) {
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

  private Complex getCrossPowerSpectrum(FFT A, FFT B, int indexRangeStart, int indexRangeEnd) {
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

  public float cVal() {
 
    return coherence;
  }

  private FFT createFFT(FFT fftBuff, float[] dataBuffY_uV, int nfft, float fs_Hz) {

    float[] fooData;
    //make the FFT objects...Following "SoundSpectrum" example that came with the Minim library
    fftBuff.window(FFT.HAMMING);
    fooData = dataBuffY_uV;  //use the raw data for the FFT
    fooData = Arrays.copyOfRange(fooData, fooData.length-nfft, fooData.length);
    fftBuff.forward(fooData); //compute FFT on this channel of data
    return fftBuff;
  }

  private float[] lrmv(float[] data) {


    int nnn = data.length;
    float[] fooData = new float[nnn];

    double dc;
    double fln;
    double slope;

    dc = 0;
    slope = 0;

    for (int i = 0; i < nnn; i++) {
      dc += data[i];
      slope += data[i]*(i+1);
    }

    dc /= (double)nnn;
    slope *= 12/(nnn*(nnn*(double)nnn-1));
    slope -= 6*dc/(nnn-1);
    fln = dc - 0.5*(nnn+1)*slope;

    for (int i = 0; i < nnn; i++) {
      fooData[i] = (float)(data[i]-(i+1)*slope+fln);
    }

    return fooData;
  }

/*  private void getCoef() {
    int cFilter = w_coherencePlot.cFilter;
    switch(cFilter) {
      case(0): 
      switch(fs) {
        case(125):
        b = new double[] {0.008826, 0.000000, -0.017652, 0.000000, 0.008826};
        a = new double[] {1.00000, -3.56745, 4.91298, -3.09242, 0.75252};
        break;
        case(200):
        b = new double[] {0.0036217, 0.0000000, -0.0072434, 0.0000000, 0.0036217};
        a = new double[] {1.00000, -3.76241, 5.36804, -3.44191, 0.83718};
        break;
        case(250):
        b = new double[] {0.0023572, 0.0000000, -0.0047144, 0.0000000, 0.0023572};
        a = new double[] {1.00000, -3.81908, 5.50870, -3.55671, 0.86747};
        break;
        case(500):
        b = new double[] {0.0006099, 0.0000000, -0.0012197, 0.0000000, 0.0006099};
        a = new double[] {1.00000, -3.91902, 5.76979, -3.78213, 0.93138};
        break;
        case(1000):
        b = new double[] {1.5515e-04, 0.0000e+00, -3.1030e-04, 0.0000e+00, 1.5515e-04};
        a = new double[] {1.00000, -3.96196, 5.88904, -3.89216, 0.96508};
        break;
        case(1600):
        b = new double[] {6.1006e-05, 0.0000e+00, -1.2201e-04, 0.0000e+00, 6.1006e-05};
        a = new double[] {1.00000, -3.97681, 5.93165, -3.93288, 0.97803};
        break;
      default:
        println("***ERROR*** FS should be 125, 200, 250, 500, 1000, 1600Hz");
        b = new double[] {1.0};
        a = new double[] {1.0};
        break;
      }
      break;
      case(1): 
      switch(fs) {
        case(125):
        b = new double[] {0.0023572, 0.0000000, -0.0047144, 0.0000000, 0.0023572};
        a = new double[] {1.00000, -3.47433, 4.87935, -3.23564, 0.86747};
        break;
        case(200):
        b = new double[] {0.0009447, 0.0000000, -0.0018894, 0.0000000, 0.0009447};
        a = new double[] {1.00000, -3.75775, 5.44304, -3.59438, 0.91498};
        break;
        case(250):
        b = new double[] {0.0006099, 0.0000000, -0.0012197, 0.0000000, 0.0006099};
        a = new double[] {1.00000, -3.83007, 5.59742, -3.69629, 0.93138};
        break;
        case(500):
        b = new double[] {1.5515e-04, 0.0000e+00, -3.1030e-04, 0.0000e+00, 1.5515e-04};
        a = new double[] {1.00000, -3.93944, 5.84457, -3.87005, 0.96508};
        break;
        case(1000):
        b = new double[] {3.9130e-05, 0.0000e+00, -7.8260e-05, 0.0000e+00, 3.9130e-05};
        a = new double[] {1.00000, -3.97594, 5.93433, -3.94077, 0.98239};
        break;
        case(1600):
        b = new double[] {1.5336e-05, 0.0000e+00, -3.0672e-05, 0.0000e+00, 1.5336e-05};
        a = new double[] {1.00000, -3.98643, 5.96183, -3.96435, 0.98895};
        break;
      default:
        println("***ERROR*** FS should be 125, 200, 250, 500, 1000, 1600Hz");
        b = new double[] {1.0};
        a = new double[] {1.0};
        break;
      }
      break;
      case(2): 
      switch(fs) {
        case(125):
        b = new double[] {0.0023572, 0.0000000, -0.0047144, 0.0000000, 0.0023572};
        a = new double[] {1.00000, -3.28733, 4.56286, -3.06148, 0.86747};
        break;
        case(200):
        b = new double[] {0.0009447, 0.0000000, -0.0018894, 0.0000000, 0.0009447};
        a = new double[] {1.00000, -3.68179, 5.30169, -3.52171, 0.91498};
        break;
        case(250):
        b = new double[] {0.0006099, 0.0000000, -0.0012197, 0.0000000, 0.0006099};
        a = new double[] {1.00000, -3.78095, 5.50392, -3.64888, 0.93138};
        break;
        case(500):
        b = new double[] {1.5515e-04, 0.0000e+00, -3.1030e-04, 0.0000e+00, 1.5515e-04};
        a = new double[] {1.00000, -3.92696, 5.82000, -3.85778, 0.96508};
        break;
        case(1000):
        b = new double[] {3.9130e-05, 0.0000e+00, -7.8260e-05, 0.0000e+00, 3.9130e-05};
        a = new double[] {1.00000, -3.97280, 5.92809, -3.93765, 0.98239};
        break;
        case(1600):
        b = new double[] {1.5336e-05, 0.0000e+00, -3.0672e-05, 0.0000e+00, 0.53e-05};
        a = new double[] {1.00000, -3.98520, 5.95938, -3.96313, 0.98895};
        break;
      default:
        println("***ERROR*** FS should be 125, 200, 250, 500, 1000, 1600Hz");
        b = new double[] {1.0};
        a = new double[] {1.0};
        break;
      }
      break;
      case(3): 
      switch(fs) {
        case(125):
        b = new double[] {0.008826, 0.000000, -0.017652, 0.000000, 0.008826};
        a = new double[] {1.00000, -3.27395, 4.40877, -2.83800, 0.75252};
        break;
        case(200):
        b = new double[] {0.0036217, 0.0000000, -0.0072434, 0.0000000, 0.0036217};
        a = new double[] {1.00000, -3.64279, 5.14619, -3.33248, 0.83718};
        break;
        case(250):
        b = new double[] {0.0023572, 0.0000000, -0.0047144, 0.0000000, 0.0023572};
        a = new double[] {1.00000, -3.74156, 5.36199, -3.48451, 0.86747};
        break;
        case(500):
        b = new double[] {0.0006099, 0.0000000, -0.0012197, 0.0000000, 0.0006099};
        a = new double[] {1.00000, -3.89919, 5.73103, -3.76300, 0.93138};
        break;
        case(1000):
        b = new double[] {1.5515e-04, 0.0000e+00, -3.1030e-04, 0.0000e+00, 1.5515e-04};
        a = new double[] {1.00000, -3.95695, 5.87913, -3.88724, 0.96508};
        break;
        case(1600):
        b = new double[] {6.1006e-05, 0.0000e+00, -1.2201e-04, 0.0000e+00, 6.1006e-05};
        a = new double[] {1.00000, -3.97484, 5.92775, -3.93094, 0.97803};
        break;
      default:
        println("***ERROR*** FS should be 125, 200, 250, 500, 1000, 1600Hz");
        b = new double[] {1.0};
        a = new double[] {1.0};
        break;
      }
      break;
      case(4): 
      switch(fs) {
        case(125):
        b = new double[] {0.06297, 0.00000, -0.12595, 0.00000, 0.06297};
        a = new double[] {1.00000, -1.92080, 2.12789, -1.22813, 0.42743};
        break;
        case(200):
        b = new double[] {0.027860, 0.000000, -0.055720, 0.000000, 0.027860};
        a = new double[] {1.00000, -2.92634, 3.64658, -2.23071, 0.58692};
        break;
        case(250):
        b = new double[] {0.018650, 0.000000, -0.037301, 0.000000, 0.018650};
        a = new double[] {1.00000, -3.21444, 4.18571, -2.59071, 0.65284};
        break;
        case(500):
        b = new double[] {0.005129, 0.000000, -0.010259, 0.000000, 0.005129};
        a = new double[] {1.00000, -3.69047, 5.20109, -3.31621, 0.80795};
        break;
        case(1000):
        b = new double[] {0.0013487, 0.0000000, -0.0026974, 0.0000000, 0.0013487};
        a = new double[] {1.00000, -3.86850, 5.63731, -3.66752, 0.89886};
        break;
        case(1600):
        b = new double[] {0.0005372, 0.0000000, -0.0010743, 0.0000000, 0.0005372};
        a = new double[] {1.00000, -3.92353, 5.78293, -3.79491, 0.93553};
        break;
      default:
        println("***ERROR*** FS should be 125, 200, 250, 500, 1000, 1600Hz");
        b = new double[] {1.0};
        a = new double[] {1.0};
        break;
      }
      break;
      case(5): 
      switch(fs) {
        case(125):
        b = new double[] {0.09131, 0.00000, -0.18263, 0.00000, 0.09131};
        a = new double[] {1.00000, 0.20141, 0.99303, 0.11330, 0.34767};
        break;
        case(200):
        b = new double[] {0.041254, 0.000000, -0.082507, 0.000000, 0.041254};
        a = new double[] {1.00000, -1.79955, 2.17562, -1.27723, 0.51398};
        break;
        case(250):
        b = new double[] {0.027860, 0.000000, -0.055720, 0.000000, 0.027860};
        a = new double[] {1.00000, -2.42203, 2.96276, -1.84629, 0.58692};
        break;
        case(500):
        b = new double[] {0.007820, 0.000000, -0.015640, 0.000000, 0.007820};
        a = new double[] {1.00000, -3.44284, 4.70965, -3.01143, 0.76601};
        break;
        case(1000):
        b = new double[] {0.0020806, 0.0000000, -0.0041611, 0.0000000, 0.0020806};
        a = new double[] {1.00000, -3.79076, 5.46309, -3.54610, 0.87521};
        break;
        case(1600):
        b = new double[] {0.0008325, 0.0000000, -0.0016651, 0.0000000, 0.0008325};
        a = new double[] {1.00000, -3.88657, 5.69467, -3.72794, 0.92007};
        break;
      default:
        println("***ERROR*** FS should be 125, 200, 250, 500, 1000, 1600Hz");
        b = new double[] {1.0};
        a = new double[] {1.0};
        break;
      }
      break;
    default:
      println("***ERROR*** FS should be 125, 200, 250, 500, 1000, 1600Hz");
      b = new double[] {1.0};
      a = new double[] {1.0};
      break;
    }
  }*/

  private void getCoef() {
      switch(fs) {

        case(125):
        b = new double[] {0.008826, 0.000000, -0.017652, 0.000000, 0.008826};
        a = new double[] {1.00000, -3.27395, 4.40877, -2.83800, 0.75252};
        break;

        case(200):
        b = new double[] {0.0036217, 0.0000000, -0.0072434, 0.0000000, 0.0036217};
        a = new double[] {1.00000, -3.64279, 5.14619, -3.33248, 0.83718};
        break;

        case(250):
        b = new double[] {0.0023572, 0.0000000, -0.0047144, 0.0000000, 0.0023572};
        a = new double[] {1.00000, -3.74156, 5.36199, -3.48451, 0.86747};
        break;

        case(500):
        b = new double[] {0.0006099, 0.0000000, -0.0012197, 0.0000000, 0.0006099};
        a = new double[] {1.00000, -3.89919, 5.73103, -3.76300, 0.93138};
        break;

        case(1000):
        b = new double[] {1.5515e-04, 0.0000e+00, -3.1030e-04, 0.0000e+00, 1.5515e-04};
        a = new double[] {1.00000, -3.95695, 5.87913, -3.88724, 0.96508};
        break;

        case(1600):
        b = new double[] {6.1006e-05, 0.0000e+00, -1.2201e-04, 0.0000e+00, 6.1006e-05};
        a = new double[] {1.00000, -3.97484, 5.92775, -3.93094, 0.97803};
        break;

      default:
        println("***ERROR*** FS should be 125, 200, 250, 500, 1000, 1600Hz");
        b = new double[] {1.0};
        a = new double[] {1.0};
        break;
      }
  }

  private float[] applyPassband(double[] filt_b, double[] filt_a, float[] data) {
    int Nback = filt_b.length;
    int n = data.length;
    float[] filtData = new float[n];
    double[] prev_y = new double[Nback];
    double[] prev_x = new double[Nback];

    //step through data points
    for (int i = 0; i < n; i++) {
      //shift the previous outputs
      for (int j = Nback-1; j > 0; j--) {
        prev_y[j] = prev_y[j-1];
        prev_x[j] = prev_x[j-1];
      }

      //add in the new point
      prev_x[0] = data[i];

      //compute the new data point
      double out = 0;
      for (int j = 0; j < Nback; j++) {
        out += filt_b[j]*prev_x[j];
        if (j > 0) {
          out -= filt_a[j]*prev_y[j];
        }
      }

      //save output value
      prev_y[0] = out;
      filtData[i] = (float)out;
    }

    return filtData;
  }
}

class Complex {
  float real;
  float imag; 
  
  public Complex(float real, float imag){
    this.real = real; 
    this.imag = imag; 
  }
  
  public Complex multi(Complex c){
    float real = this.real * c.real - this.imag * c.imag;
    float imag = this.real * c.imag + this.imag * c.real;
    return new Complex(real, imag);
  }
  
  public void setReal(float n){
  
    real = n;
  }
  
  public void setImag(float n){
  
    imag = n;
  }
  
  public float getReal(){
  
    return real;
  }
  
  public float getImag(){
  
    return imag;
  }
}
