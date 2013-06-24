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
package com.blockwithme.meta.infrastructure;

import com.blockwithme.meta.types.Named;
import com.tinkerpop.frames.Adjacency;
import com.tinkerpop.frames.annotations.gremlin.GremlinGroovy;
import com.tinkerpop.frames.annotations.gremlin.GremlinParam;
import com.tinkerpop.frames.typed.TypeValue;

/**
 * A data-center contains one or more computer clusters.
 *
 * We assume Clusters are statically configured...
 *
 * @author monster
 */
@TypeValue("DataCenter")
public interface DataCenter extends Named {
    /** Returns our clusters in this data-center. */
    @Adjacency(label = "contains")
    Cluster[] getClusters();

    /** Adds a Cluster. */
    @Adjacency(label = "contains")
    void addCluster(final Cluster cluster);

    /** Removes a Cluster. */
    @Adjacency(label = "contains")
    void removeCluster(final Cluster cluster);

    /** Returns the cluster with the given name, if any. */
    @GremlinGroovy("it.out('contains').has('name',name)")
    Cluster findCluster(@GremlinParam("name") final String name);
}
