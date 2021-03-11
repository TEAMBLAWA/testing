module.exports = function(grunt) {

  require('load-grunt-tasks')(grunt);
  // Project configuration.
  grunt.initConfig({
    pkg: grunt.file.readJSON('package.json'),
    shell: {
      yarn_build: {
        command: 'yarn build --silent'
      }
    },
    execute: {
      build_rules: {
        src: ['node_modules/fireplan/fireplan'],
        options: {
          args: ['rules.yaml']
        }
      }
    },
  });
  grunt.registerTask('dist', [ 'shell:yarn_build', 'execute:build_rules' ]);
  grunt.registerTask('dist-enterprise', [ 'dist' ]);
  grunt.registerTask('default', ['dist']);

};