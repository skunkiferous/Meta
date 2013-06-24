/*
 * Copyright (C) 2013 Sebastien Diot.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.blockwithme.meta.types;

import com.tinkerpop.frames.Adjacency;
import com.tinkerpop.frames.Property;
import com.tinkerpop.frames.annotations.gremlin.GremlinGroovy;
import com.tinkerpop.frames.annotations.gremlin.GremlinParam;
import com.tinkerpop.frames.typed.TypeValue;

/**
 * A bundle is a grouping of resources. Typically types, but also media-files.
 *
 * The static data comes from configuration files in the bundle (jar) itself.
 *
 * @author monster
 */
@TypeValue("Bundle")
public interface Bundle extends Named {
    /** Returns the owning Application. */
    @Adjacency(label = "usedBy")
    Feature getFeature();

    /** Sets the owning Application. */
    @Adjacency(label = "usedBy")
    void setFeature(final Feature feature);

    /** Returns the bundle version. */
    @Property("version")
    String getVersion();

    /** Sets the bundle version. */
    @Property("version")
    void setVersion(final String version);

    /** Returns the bundle version, as a comparable int. */
    @GremlinGroovy(value = "com.blockwithme.meta.Statics.versionToInt(it.version)", frame = false)
    int getVersionAsInt();

    /** List the exported types defined in this bundle. */
    @Adjacency(label = "exports")
    Type[] getExports();

    /** Adds a new export. */
    @Adjacency(label = "exports")
    void addExport(final Type type);

    /** Removes an export. */
    @Adjacency(label = "exports")
    void removeExport(final Type type);

    /** Returns the exported type with the given name, if any. */
    @GremlinGroovy("it.out('exports').has('name',name)")
    Type findExport(@GremlinParam("name") final String name);

    /** List the bundle's dependencies. */
    @Adjacency(label = "dependsOn")
    Dependency[] getDependencies();

    /** Adds a new Dependency. */
    @Adjacency(label = "dependsOn")
    void addDependency(final Dependency dependency);

    /** Removes a Dependency. */
    @Adjacency(label = "dependsOn")
    void removeDependency(final Dependency dependency);

    /** Returns the Dependency with the given name, if any. */
    @GremlinGroovy("it.out('dependsOn').has('name',name)")
    Dependency findDependency(@GremlinParam("name") final String name);

    /** All the services offered by this bundle. */
    @Adjacency(label = "offers")
    Service[] getServices();

    /** Adds a new service. */
    @Adjacency(label = "offers")
    void addService(final Service service);

    /** Removes a service. */
    @Adjacency(label = "offers")
    void removeService(final Service service);

    /** Returns the Service with the given name, if any. */
    @GremlinGroovy("it.out('offers').has('name',name)")
    Service findService(@GremlinParam("name") final String name);

    /** Returns the current lifecycle of the bundle. */
    @Property("lifecycle")
    BundleLifecycle getLifecycle();

    /** Sets the current lifecycle of the bundle. */
    @Property("lifecycle")
    void setLifecycle(final BundleLifecycle lifecycle);
}
