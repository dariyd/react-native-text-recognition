# react-native-text-recognition (only IOS now)
This is a React Native module to use ios VisinKit framework and VNDocumentScanner to scan documents
## Getting started

`$ yarn add https://github.com/dariyd/react-native-text-recognition.git`

### automatic installation

`$ cd ios && pod install`

## Usage
```javascript
import {recognizeText} from 'react-native-text-recognition';

const detectText = async () => {
  const results = await recognizeText('https://images.wapcar.my/file1/ad1db41b20ef4cceaea3ff0fe5bd3690_800.jpg');
  console.log('Results', results);
};
```
# API Reference

## Methods

```js
import {recognizeText} from 'react-native-text-recognition';
```

### `recognizeText(url)`

Recognize text in image specified by url

See [Parameters](#parameters) for further information on `parameters`.

The `callback` will be called with a response object, refer to [The Response Object](#the-response-object).


## Parameters

| Name         | iOS | Description                                                                                                                               |
| -------------- | --- |----------------------------------------------------------------------------------------------------------------------------------------- |
| url        | OK  |url to local or remote img with text. Url can also be to image taken from camera or selected from gallery 
                                                   |

## The Response Object

| key          | iOS |Description                                                         |
| ------------ | --- |------------------------------------------------------------------- |
| didCancel    | OK  |`true` if the user cancelled the process                            |
| error        | OK  |`true` if error happens                |
| errorMessage | OK  |Description of the error, use it for debug purpose only             |
| detectedWords       | OK  |Array of the detected words, [refer to Word Object](#Word-Object) |

## Word Object

| key       | iOS | Description               |
| --------- | --- | ------------------------- |
| text    | OK  | Recognzied text string |
| confidence     | OK  | recognition confidence                |
