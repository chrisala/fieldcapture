package au.org.ala.merit

import com.vividsolutions.jts.geom.Geometry
import com.vividsolutions.jts.geom.Point
import com.vividsolutions.jts.io.WKTReader
import grails.converters.JSON
import org.codehaus.groovy.grails.web.mapping.LinkGenerator
import org.geotools.geojson.geom.GeometryJSON
import org.geotools.kml.v22.KMLConfiguration
import org.geotools.xml.Parser
import org.opengis.feature.simple.SimpleFeature

class SiteService {

    def webService, grailsApplication, commonService, metadataService, userService, reportService
    def documentService
    LinkGenerator grailsLinkGenerator

    def list() {
        webService.getJson(grailsApplication.config.ecodata.baseUrl + 'site/').list
    }

    def projectsForSite(siteId) {
        get(siteId)?.projects
    }

    /**
     * Creates a site extent object from a supplied latitude and longitude in the correct format, and populates the facet metadata for the extent.
     * @param lat the latitude of the point.
     * @param lon the longitude of the point.

     */
    def siteExtentFromPoint(lat, lon) {

        def extent = [:].withDefault{[:]}
        extent.source = 'point'
        extent.geometry.type = 'Point'
        extent.geometry.decimalLatitude = lat
        extent.geometry.decimalLongitude = lon
        extent.geometry.coordinates = [lon, lat]
        extent.geometry.centre = [lon, lat]
        extent.geometry << metadataService.getLocationMetadataForPoint(lat, lon)
        extent
    }

    def getLocationMetadata(site) {
        //log.debug site
        def loc = getFirstPointLocation(site)
        //log.debug "loc = " + loc
        if (loc && loc.geometry?.decimalLatitude && loc.geometry?.decimalLongitude) {
            return metadataService.getLocationMetadataForPoint(loc.geometry.decimalLatitude, loc.geometry.decimalLongitude)
        }
        return null
    }

    void addPhotoPointPhotosForSites(List<Map> sites, List activities, List projects) {

        long start = System.currentTimeMillis()
        List siteIds = sites.collect{it.siteId}
        List pois = sites.collect{it.poi?it.poi.collect{poi->poi.poiId}:[]}.flatten()
        if (pois) {


            Map documents = documentService.search(siteId: siteIds)

            if (documents.documents) {

                Map docsByPOI = documents.documents.groupBy{it.poiId}
                sites.each { site->

                    site.poi?.each { poi ->
                        poi.photos = docsByPOI[poi.poiId]
                        poi.photos?.each{ photo ->
                            photo.activity = activities?.find{it.activityId == photo.activityId}
                            photo.projectId = photo.activity?.projectId ?: photo.projectId
                            Map project = projects.find{it.projectId == photo.projectId}
                            if (photo.activity) {

                                if (!project.reports) {
                                    project.reports = reportService.getReportsForProject(photo.projectId)
                                }
                                Map report = reportService.findReportForDate(photo.activity.plannedEndDate, project.reports)
                                photo.stage = report?report.name:''
                            }
                            photo.projectName = project?.name?:''
                            photo.siteName = site.name
                            photo.poiName = poi.name

                        }
                        poi.photos?.sort{it.dateTaken || ''}
                        poi.photos = poi.photos?.findAll{it.projectId} // Remove photos not associated with a supplied project
                    }
                }
            }
        }
        long end = System.currentTimeMillis()
        log.debug "Photopoint initialisation took ${(end-start)} millis"
    }

    def injectLocationMetadata(List sites) {
        sites.each { site ->
            injectLocationMetadata(site)
        }
        sites
    }

    def injectLocationMetadata(Object site) {
        def loc = getFirstPointLocation(site)
        if (loc && loc.geometry?.decimalLatitude && loc.geometry?.decimalLongitude) {
            site << metadataService.getLocationMetadataForPoint(loc.geometry.decimalLatitude, loc.geometry.decimalLongitude)
        }
        site
    }

    def getFirstPointLocation(site) {
        site.location?.find {
            it.type == 'locationTypePoint'
        }
    }

    def getSitesFromIdList(ids) {
        def result = []
        ids.each {
            result << get(it)
        }
        result
    }

    def addPhotoPoint(siteId, photoPoint) {
        photoPoint.type = 'photopoint'
        updatePOI(siteId, photoPoint)
    }

    def updatePOI(String siteId, Map poi) {

        if (!siteId) {
            throw new IllegalArgumentException("The siteId parameter cannot be null")
        }
        def url = "${grailsApplication.config.ecodata.baseUrl}site/${siteId}/poi"
        webService.doPost(url, poi)
    }

    int deletePOI(String siteId, String poiId) {
        def url = "${grailsApplication.config.ecodata.baseUrl}site/${siteId}/poi/${poiId}"
        webService.doDelete(url)
    }

    def get(id, Map urlParams = [:]) {
        if (!id) return null
        webService.getJson(grailsApplication.config.ecodata.baseUrl + 'site/' + id +
                commonService.buildUrlParamsFromMap(urlParams))
    }

    def getRaw(id) {
        def site = get(id, [raw:'true'])
        if (!site || site.error) return [:]
        def documents = documentService.getDocumentsForSite(site.siteId).resp?.documents?:[]
        [site: site, documents:documents as JSON]
    }

    def updateRaw(id, values) {
        //if its a drawn shape, save and get a PID
        if(values?.extent?.source == 'drawn'){
            def shapePid = persistSiteExtent(values.name, values.extent.geometry)
            values.extent.geometry.pid = shapePid.resp?.id
        }
        values.visibility = 'private'

        if (id) {
            update(id, values)
            [status: 'updated']
        } else {
            def resp = create(values)
            [status: 'created', id:resp.resp.siteId]
        }
    }

    def create(body){
        webService.doPost(grailsApplication.config.ecodata.baseUrl + 'site/', body)
    }

    def update(id, body) {
        webService.doPost(grailsApplication.config.ecodata.baseUrl + 'site/' + id, body)
    }

    def updateProjectAssociations(body) {
        webService.doPost(grailsApplication.config.ecodata.baseUrl + 'project/updateSites/' + body.projectId, body)
    }

    /** uploads a shapefile to the spatial portal */
    def uploadShapefile(shapefile) {
        def userId = userService.getUser().userId
        def url = "${grailsApplication.config.spatial.layersUrl}/shape/upload/shp?user_id=${userId}&api_key=${grailsApplication.config.api_key}"

        return webService.postMultipart(url, [:], shapefile)
    }

    /**
     * Creates a site for a specified project from the supplied site data.
     * @param shapeFileId the id of the shapefile in the spatial portal
     * @param siteId the id of the shape to use (as returned by the spatial portal upload)
     * @param name the name for the site
     * @param description the description for the site
     * @param projectId the project the site should be associated with.
     */
    def createSiteFromUploadedShapefile(shapeFileId, siteId, externalId, name, description, projectId) {
        def baseUrl = "${grailsApplication.config.spatial.layersUrl}/shape/upload/shp"
        def userId = userService.getUser().userId

        def site = [name:name, description: description, user_id:userId, api_key:grailsApplication.config.api_key]

        def url = "${baseUrl}/${shapeFileId}/${siteId}"

        def result = webService.doPost(url, site)
        if (!result.error) {
            String pid = result.resp.id

            Map geometry = siteGeometry(pid)
            createSite(projectId, name, description, externalId, pid, geometry)
        }
    }

    /**
     * Creates (and saves) a site definition from a name, description and lat/lon.
     * @param projectId the project the site should be associated with.
     * @param name a name for the site.
     * @param description a description of the site.
     * @param lat latitude of the site centroid.
     * @param lon longitude of the site centroid.
     */
    def createSiteFromPoint(projectId, name, description, lat, lon) {
        def site = [name:name, description:description, projects:[projectId]]
        site.extent = siteExtentFromPoint(lat, lon)

        create(site)
    }

    /**
     * Creates sites for a project from the supplied KML.  The Placemark elements in the KML are used to create
     * the sites, other contextual and styling information is ignored.
     * @param kml the KML that defines the sites to be created
     * @param projectId the project the sites will be assigned to.
     */
    def createSitesFromKml(String kml, String projectId) {

        def url = "${grailsApplication.config.spatial.layersUrl}/shape/upload/wkt"
        def userId = userService.getUser().userId

        Parser parser = new Parser(new KMLConfiguration())
        SimpleFeature f = parser.parse(new StringReader(kml))

        def placemarks = []
        extractPlacemarks(f, placemarks)

        def sites = []

        placemarks.each { SimpleFeature placemark ->
            def name = placemark.getAttribute('name')
            def description = placemark.getAttribute('description')

            Geometry geom = placemark.getDefaultGeometry()
            Map geojson = JSON.parse(new GeometryJSON().toString(geom))

            def site = [name:name, description: description, user_id:userId, api_key:grailsApplication.config.api_key, wkt:geom.toText()]

            def result = webService.doPost(url, site)
            if (!result.error) {
                def id = result.resp.id
                if (!result.resp.error) {
                    sites << createSite(projectId, name, description, '', id, geojson)
                }
            }

        }
        return sites
    }

    /**
     * Extracts any features that have a geometry attached, in the case of KML these will likely be placemarks.
     */
    def extractPlacemarks(features, placemarks) {
        if (!features) {
            return
        }
        features.each { SimpleFeature feature ->
            if (feature.getDefaultGeometry()) {
                placemarks << feature
            }
            else {
                extractPlacemarks(feature.getAttribute('Feature'), placemarks)
            }
        }
    }


    Map siteGeometry(String spatialPortalSiteId) {
        def getGeoJsonUrl = "${grailsApplication.config.spatial.baseUrl}/ws/shape/geojson"
        webService.getJson("${getGeoJsonUrl}/${spatialPortalSiteId}")
    }

    def createSite(String projectId, String name, String description, String externalId, String geometryPid, Map geometry) {
        geometry.pid = geometryPid
        def values = [extent: [source: 'pid', geometry: geometry, pid:geometryPid], projects: [projectId], name: name, description: description, externalId:externalId, visibility:'private']
        return create(values)
    }

    def persistSiteExtent(name, geometry) {

        def resp = null
        if(geometry?.type == 'Circle'){
           def body = [name: "test", description: "my description", user_id: "1551", api_key: "b3f3c932-ba88-4ad5-b429-f947475024af"]
           def url = grailsApplication.config.spatial.layersUrl + "/shape/upload/pointradius/" +
                    geometry?.coordinates[1] + '/' + geometry?.coordinates[0] + '/' + (geometry?.radius / 1000)
           resp = webService.doPost(url, body)
        } else if (geometry?.type == 'Polygon'){
           def body = [geojson: geometry, name: name, description:'my description', user_id: '1551', api_key: "b3f3c932-ba88-4ad5-b429-f947475024af"]
           resp = webService.doPost(grailsApplication.config.spatial.layersUrl + "/shape/upload/geojson", body)
        }
        resp
    }

    def delete(id) {
        webService.doDelete(grailsApplication.config.ecodata.baseUrl + 'site/' + id)
    }

    def deleteSitesFromProject(String projectId, List siteIds, boolean deleteOrphans = true){
        webService.doPost(grailsApplication.config.ecodata.baseUrl + 'project/deleteSites/' + projectId, [siteIds:siteIds, deleteOrphans:deleteOrphans])
    }

    /**
     * Returns json that describes in a generic fashion the features to be placed on a map that
     * will represent the site's locations.
     *
     * If no extent is defined, returns an empty JSON object.
     *
     * @param site
     */
    def getMapFeatures(site) {
        def featuresMap = [zoomToBounds: true, zoomLimit: 15, highlightOnHover: true, features: []]
        switch (site.extent?.source) {
            case 'point':
                featuresMap.features << site.extent.geometry
                break
            case 'pid':
                featuresMap.features << site.extent.geometry
                break
            case 'drawn' :
                featuresMap.features << site.extent.geometry
                break
            default:
                featuresMap = [:]
        }

        def asJSON = featuresMap as JSON

        log.debug asJSON

        asJSON
    }

    def lookupLocationMetadataForSite(Map site) {
        Map resp = webService.doPost(grailsApplication.config.ecodata.baseUrl + 'site/lookupLocationMetadataForSite', site)
        if (resp.resp) {
            return resp.resp
        }
        resp
    }
}