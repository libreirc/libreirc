const webpack = require('webpack');

var plugins = [];
if (process.env.WEBPACK === 'release') {
  plugins.push(new webpack.optimize.UglifyJsPlugin({ compress: { warnings: false } }));
}

module.exports = {
  entry: './src/main.js',
  output: { path: 'build', publicPath: 'build', filename: '_bundle.js' },
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
