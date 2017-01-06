'use strict';
const path = require('path');
const webpack = require('webpack');
const autoprefixer = require('autoprefixer');
const ExtractTextPlugin = require('extract-text-webpack-plugin');


// Always enabled plugins
let plugins = [
  // Extract CSS files to the 'bundle.css'.
  new ExtractTextPlugin('_bundle.css')
];

// Production only plugins
if (process.env.NODE_ENV === 'production') {
  plugins = plugins.concat([
    // Pass the 'NODE_ENV=production' environment variable to the child processes.
    new webpack.DefinePlugin({ 'process.env': { NODE_ENV: JSON.stringify('production') } }),
    // Minimize the output
    new webpack.optimize.UglifyJsPlugin({ compress: { warnings: false } }),
  ]);
}


// Configs
module.exports = {
  entry: './main.js',
  context: path.resolve(__dirname, 'src'),
  output: {
    filename: '_bundle.js',
    path: `${__dirname}/../server/public/build`,
    publicPath: '/build/',
  },
  module: {
    loaders: [
      { test: /\.txt$/, loader: 'raw' },
      { test: /\.(?:png|(?:woff2?|ttf|eot|svg)(?:\?v=[0-9]\.[0-9]\.[0-9])?)$/, loader: 'file?name=static/[hash].[ext]' },
      { test: /\.css$/, loader: ExtractTextPlugin.extract('style', 'css') },
      { test: /\.styl$/, loader: ExtractTextPlugin.extract('style', 'css!postcss!stylus') },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: 'elm-webpack'
      }
    ]
  },
  plugins,
  devtool: 'source-map',
  postcss: _ => [autoprefixer]
};
