// @flow
const webpack = require('webpack');

var plugins/*: Array<Object>*/ = [];
if (process.env.WEBPACK === 'release') {
  plugins.push(new webpack.optimize.UglifyJsPlugin({ compress: { warnings: false } }));
}

module.exports = {
  context: `${__dirname}/src`,
  entry: './main.js',
  output: {
    path: `${__dirname}/../server/public/build`,
    publicPath: '/build/',
    filename: '_bundle.js'
  },
  devtool: 'source-map',
  plugins: plugins,
  module: {
    loaders: [
      {
        test: /\.jsx?$/,
        exclude: /node_modules/,
        loader: 'babel',
        query: { presets: ['es2015', 'stage-3', 'react'] }
      }
    ]
  }
};
