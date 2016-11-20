const webpack = require('webpack');
const autoprefixer = require('autoprefixer');
const ExtractTextPlugin = require('extract-text-webpack-plugin');

// Always enabled plugins
const plugs = [
  new ExtractTextPlugin('_bundle.css')
];

// Production only plugins
const prod = [
  new webpack.DefinePlugin({ 'process.env': { NODE_ENV: JSON.stringify('production') } }),
  new webpack.optimize.UglifyJsPlugin({ compress: { warnings: false } })
];

module.exports = {
  entry: './main.js',
  context: `${__dirname}/src`,
  output: {
    filename: '_bundle.js',
    path: `${__dirname}/../server/public/build`,
    publicPath: '/build/',
  },
  module: {
    loaders: [
      { test: /\.txt$/, loader: 'raw' },
      { test: /\.png$/, loader: 'file?name=static/[hash].[ext]' },
      { test: /\.(woff2?|ttf|eot|svg)(\?v=[0-9]\.[0-9]\.[0-9])?$/, loader: 'file?name=static/[hash].[ext]' },
      { test: /\.css$/, loader: ExtractTextPlugin.extract('style', 'css') },
      { test: /\.styl$/, loader: ExtractTextPlugin.extract('style', 'css!postcss!stylus') },
      {
        test: /\.jsx?$/,
        exclude: /node_modules/,
        loader: 'babel',
        query: { presets: ['latest'] }
      },
      {
        test: /\.elm$/,
        exclude: [/elm-stuff/, /node_modules/],
        loader: 'elm-webpack'
      }
    ]
  },
  plugins: process.env.NODE_ENV !== 'production' ? plugs : plugs.concat(prod),
  devtool: 'source-map',
  postcss: _ => [autoprefixer]
};
