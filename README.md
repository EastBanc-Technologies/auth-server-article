###Intro

In this article we would like to share our experience of [ForgeRock's Open Identity Stack][1] products customization and deployment automation. There are three main reasons to automate these things:

 - You do not want to buy support and you want to run enterprise releases in production; The ForgeRock Open Identity stack is a 100 percent open source solution. The source code is available under the CDDL Version 1.0 license and can be downloaded from ForgeRock.org. That means that you basically can build you own binary without buying a subscription. Of course support as well as access to maintenance releases will not be available in this case and we do not recommend this approach in general;
 - The complexity of installation process; The installation process is described in [OpenAM Install Guide][2] but from our experience it is complex and error-prone enough to repeat them manually for each environment you may have (dev/qa/prod). It is also would be terrific wasting of time to ask programmers to pass through this guide;
 - Custom configuration; OpenAM is a general purpose access control management software consists of plenty of modules. Every module is highly configurable by own set of text configuration files. Most likely you will collect significant amount of changes in config files pretty soon and you will realize that it is getting hard to track them manually.

###What we've done

As part of IT consulting services for the one of our very interesting customer working in brokerage domain we designed and implemented custom access control solution based on ForgeRock's Open Identity Stack.
In short we leveraged OpenAM as authentication provider, Auth2 server and policy decision point.
OpenDJ is served as a storage for all access control related information - users, roles, permissions etc... .
OpenDJ was used for synchronizing data between application database and OpenDJ but later was replaced them with custom solution based on Apache Camel which we will probably describe in our next article.


###Building your own binaries of _ForgeRock Open Identity Stack_

####Preparing installation

Since 11 version OpenAM supports Java 7. You also have to have Apache Maven and Apache Ant binaries available in your path.

####Downloading sources

As I mentioned above a source code is available on ForgeRock.org or can be checked out using Subversion client, but you still need to register an account on [ForgeRock's site][3] first.

```bash

# create work directory
mkdir auth-server && cd auth-server
# checkout OpenAM 11
svn co https://svn.forgerock.org/openam/tags/11.0.0/openam
# checkout OpenDJ 2.6.0
svn co https://svn.forgerock.org/opendj/tags/2.6.0/
# for convenience rename to 'opendj' directory
mv 2.6.0 opendj
```

####Building sources

Both project OpenDJ and OpenAM use Apache Maven so it's quite simple to build them. Build order is not important.
but be patient OpenDJ build takes about 14 minutes on my MacBook Pro. OpenAM build time is about 5 minutes.

```bash

# build OpenDJ main project
mvn clean install -f opendj/pom.xml
# build OpenAM main project
mvn clean install -f openam/pom.xml
```

Note. At the moment of writing i could not build OpenAM project on Maven 3.2.1 because of the issue with copy-maven-plugin (https://github.com/evgeny-goldin/maven-plugins/issues/10)
but build successfully passed for Maven 3.0.5 version.

Note. If you will run into the following error:
`Execution default-war of goal org.apache.maven.plugins:maven-war-plugin:2.4:war failed: basedir [WORK_DIR]/openam/target/legal-notices`
create empty directory `mkdir -p [WORK_DIR]/openam/target/legal-notices` and run `mvn install` again


At this step we have all necessary packages in the local Maven repository. It makes a lot of sense to deploy artifacts to the corporate repository server - Nexus, Artifactory etc...
but not required in the context of this article.



###Design and build _access control management_ software distribution package

In this article we assume that you use Maven but if you do not we hope it would be easy to adopt these steps to another build tool.


####Create multi module maven project

First of all we need to create multi module maven project:

```bash

mvn archetype:generate -DarchetypeGroupId=org.codehaus.mojo.archetypes -DarchetypeArtifactId=pom-root -DarchetypeVersion=RELEASE

```
You will be asked for project group id, artifact id and packaging type. In my case the answers are:
  groupId = com.company
  artifactId = access-control
  packaging = pom

Now we create a module for the distribution package

```bash

cd access-control
mvn archetype:generate -DarchetypeGroupId=org.apache.maven.archetypes -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=RELEASE
```

output from ny console:

```
Define value for property 'groupId': : com.company
Define value for property 'artifactId': : distr
Define value for property 'version':  1.0-SNAPSHOT: :
Define value for property 'package':  com.company: :
```

####Configure distribution maven module

The main components of our access control management solution of course are OpenAM and OpenDJ.
OpenAM is a java web application so it requires a container or application server as running environment.
According to installation guide OpenAM examples often use Apache Tomcat as the deployment container.
Let's follow that practice and include Apache Tomcat in our distribution package.
We also want to be able to apply custom settings during installation so we need to include SSOAdminTools and SSOConfiguratorTools
- the OpenAM configuration utilities.

`distr` module pom.xml snippet

```xml

    <properties>
        ....
        <tomcat.version>7.0.42</tomcat.version>
        <opendj.version>2.6.0</opendj.version>
        <openam.version>11.0.0</openam.version>
    </properties>

    <dependencies>
        ....
        <dependency>
            <groupId>org.apache.tomcat</groupId>
            <artifactId>tomcat</artifactId>
            <version>${tomcat.version}</version>
            <type>tar.gz</type>
        </dependency>

        <dependency>
            <groupId>org.forgerock.openam</groupId>
            <artifactId>openam-server</artifactId>
               <version>${openam.version}</version>
            <type>war</type>
        </dependency>

        <dependency>
            <groupId>org.forgerock.openam</groupId>
            <artifactId>openam-distribution-ssoadmintools</artifactId>
            <version>${openam.version}</version>
            <type>zip</type>
        </dependency>

        <dependency>
            <groupId>org.forgerock.openam</groupId>
            <artifactId>openam-distribution-ssoconfiguratortools</artifactId>
            <version>${openam.version}</version>
            <type>zip</type>
        </dependency>

        <dependency>
            <groupId>org.forgerock.opendj</groupId>
            <artifactId>opendj-server</artifactId>
            <version>${opendj.version}</version>
            <type>zip</type>
        </dependency>
        ....
    </dependencies>
```

Make sure that all dependencies are resolved correctly by invoking `mvn clean install` command.


####Add assembly plugin configuration

[Maven Assembly Plugin][4] is a perfect tool for building distribution packages.
The plugin comes with own configuration descriptor which is usually moved to separate file  - `assembly.xml`
located in module root.

```xml

    <plugin>
        <artifactId>maven-assembly-plugin</artifactId>
            <executions>
                <execution>
                    <id>build-distr</id>
                    <phase>package</phase>
                    <goals>
                        <goal>single</goal>
                    </goals>
                </execution>
            </executions>
            <configuration>
            <appendAssemblyId>false</appendAssemblyId>
            <finalName>access-control-package</finalName>
            <descriptors>
                <descriptor>assembly.xml</descriptor>
            </descriptors>
        </configuration>
    </plugin>
```

Let's start from building tar file which contains ForgeRock binaries we've built earlier.
We have them specified as `distr` module dependencies so that we need to instruct Assemply plugin to include project dependencies:

```xml
<assembly xmlns="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.0"
          xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
          xsi:schemaLocation="http://maven.apache.org/plugins/maven-assembly-plugin/assembly/1.1.0 http://maven.apache.org/xsd/assembly-1.1.0.xsd">
    <id>access-control-package</id>
    <formats>
        <format>tar.gz</format>
    </formats>
    <includeBaseDirectory>true</includeBaseDirectory>
    <dependencySets>
        <dependencySet>
            <outputDirectory>/lib</outputDirectory>
            <useProjectArtifact>false</useProjectArtifact>
            <unpack>false</unpack>
            <useTransitiveDependencies>false</useTransitiveDependencies>
            <outputFileNameMapping>${artifact.artifactId}-${artifact.baseVersion}.${artifact.extension}</outputFileNameMapping>
        </dependencySet>
    </dependencySets>

</assembly>
```

To make sure everything is okay so far type `mvn install` and check out target directory.
```

$ tar -ztf target/auth-server.tar.gz
auth-server/lib/tomcat-7.0.42.tar.gz
auth-server/lib/openam-server-11.0.0.war
auth-server/lib/openam-distribution-ssoadmintools-11.0.0.zip
auth-server/lib/openam-distribution-ssoconfiguratortools-11.0.0.zip
auth-server/lib/opendj-server-2.6.0.zip
```

At this point we are ready to create installation scripts

###Create installation scripts




  [1]: http://forgerock.com/products/open-identity-stack/
  [2]: http://openam.forgerock.org/openam-documentation/openam-doc-source/doc/install-guide
  [3]: https://backstage.forgerock.com/#/account/register
  [4]: https://maven.apache.org/plugins/maven-assembly-plugin/
