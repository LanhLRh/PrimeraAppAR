//
//  ViewController.swift
//  PrimeraAppAR
//
//  Created by yo on 3/6/18.
//  Copyright © 2018. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {

    // Objeto para ver los objetos AR
    @IBOutlet weak var sceneView: ARSCNView!
    
    // Al cargar la pantalla
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Agrega la deteccion de taps a la pantalla
        addTapGestureToSceneView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Al iniciar
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        // Configura la sesion
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        
        sceneView.session.run(configuration)
        sceneView.delegate = self
        
        // Muestra los puntos que detecta a partir de los cuales se creara un plano
        sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        addBox() // Agrega la caja a la vista
    }
    
    // Agrega una caja con una posicion default
    func addBox() {
        // Crea un objeto caja con ciertas dimensiones
        let box = SCNBox(width: 0.05, height: 0.05, length: 0.05, chamferRadius: 0)

        // Crea un nodo (para agregar objetos)
        let boxNode = SCNNode()
        // Le asigna la forma del objeto box al nodo
        boxNode.geometry = box
        // Le asigna posicion a la caja
        boxNode.position = SCNVector3(0, 0, -0.2)
        
        // Agrega la caja al arbol para mostrarlo en pantalla
        sceneView.scene.rootNode.addChildNode(boxNode)
        
    }
    
    // Agrega el tap recognizer al sceneView ARSCNView (pantalla)
    func addTapGestureToSceneView() {
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(ViewController.didTabForPlane(withGestureRecognizer:)))
        sceneView.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    
    @objc func didTabForPlane(withGestureRecognizer recognizer: UIGestureRecognizer) {
        
        let tapLocation = recognizer.location(in: sceneView)
        let hitTestResult = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
        // .existingPlane o .existingPlaneUsingExtent
        
        // Si el rayo choca con algo, sigue, sino termina el metodo
        guard let hitResult = hitTestResult.first else { return }
        
        let translation = hitResult.worldTransform.translation
        let x = translation.x
        let y = translation.y
        let z = translation.z
        
        addBox(x: x, y: y, z: z)
    }
    
    // Detecta el tap a la pantalla y borra el cubo al que apunta el tap
    // Si no hay caja, crea una en la posicion
    @objc func didTap(withGestureRecognizer recognizer: UIGestureRecognizer) {
        
        //
        let tapLocation = recognizer.location(in: sceneView)
        
        let hitTestResult = sceneView.hitTest(tapLocation)
        guard let node = hitTestResult.first?.node else {
            
            let hitTestResultWithFeaturePoints = sceneView.hitTest(tapLocation, types: .featurePoint)
            
            if let hitTestResult = hitTestResultWithFeaturePoints.first {
                let translation = hitTestResult.worldTransform.translation
                addBox(x: translation.x, y: translation.y, z: translation.z)
            }
            
            return
        }
        // Remueve el plano de la vista
        node.removeFromParentNode()
    }
    
    // Agrega una caja en la posicion recibida
    func addBox(x: Float = 0, y: Float = 0, z: Float = -0.2) {
        let box = SCNBox(width: 0.05,
                        height: 0.05,
                        length: 0.05,
                        chamferRadius: 0)
        
        let boxNode = SCNNode()
        boxNode.geometry = box
        boxNode.position = SCNVector3(x, y, z)
        
        sceneView.scene.rootNode.addChildNode(boxNode)
    }
    
}

extension ViewController : ARSCNViewDelegate {
    
    // Crea un plano al ser detectado
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        // Informacion del plano que se encontro
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Medidas del plano encontrado
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        
        // Se crea un plano con las medidas
        let plane = SCNPlane(width: width, height: height)
        
        // Color del plano
        plane.materials.first?.diffuse.contents = UIColor.lightGray
        
        // Se crea un nodo con la forma del plano creado
        let planeNode = SCNNode(geometry: plane)
        
        // Posicion del plano
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        
        // Se le asigna al nodo la posicion del plano
        planeNode.position = SCNVector3(x,y,z)
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.opacity = 0.5
        
        // Se agrega el nodo (plano) a la vista
        node.addChildNode(planeNode)
    }
    
    // Actualiza el plano creado
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let planeAnchor = anchor as? ARPlaneAnchor,
        let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane else {
                return
        }
        
        let width = CGFloat(planeAnchor.extent.x)
        let height = CGFloat(planeAnchor.extent.z)
        
        plane.width = width
        plane.height = height
        
        // Posicion del plano
        let x = CGFloat(planeAnchor.center.x)
        let y = CGFloat(planeAnchor.center.y)
        let z = CGFloat(planeAnchor.center.z)
        
        // Se le asigna al nodo la posicion del plano
        planeNode.position = SCNVector3(x,y,z)
        
    }
}

// Traduce la matriz de posicion obtenida por hitTestResult.worldTransform y la convierte en una matriz de x, y, z (3 dimenciones)
extension float4x4 {
    var translation: float3 {
        
        let translation = self.columns.3
        return float3(translation.x, translation.y, translation.z)
        
    }
}

