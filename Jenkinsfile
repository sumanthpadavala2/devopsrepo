pipeline {
	agent any
		triggers {
			githubPush()
			}
	stages{
		stage('echo') {
			steps {
				echo 'Hello from Jenkins'
			     }
			}
		}
	}
