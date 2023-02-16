local gw = {}
x=40
y=150
w=75
h=200
speedx=0.2
speedy=0.2

function gw.create()
end

function gw.update(dt)
    x=x+speedx

    if x>640-w then speedx=-speedx end
    if x<0 then speedx=-speedx end

    y=y+speedy

    if y>480-h then speedy=-speedy end
    if y<0 then speedy=-speedy end


end

function gw.render()
    graphics.setClearColor(0,0.2,0.5,1)
    --graphics.setDrawColor(0.7,0.5,0,1)
    graphics.drawRect(x,y,w,h, 0.5,0,0.5,1)
    graphics.drawRect(x+25,y+60,5,5, 0,0.8,0.7,1)
    graphics.drawRect(x+45,y+60,5,5, 0,0.8,0.7,1)
    graphics.drawRect(x+30,y+100,20,3, 0,0.8,0.7,1)
    graphics.drawRect(x+25,y+95,5,5, 0,0.8,0.7,1)
    graphics.drawRect(x+50,y+95,5,5, 0,0.8,0.7,1)

    graphics.print("SPEEDY",x+10, y, {0,0.8,0.7,1})
end

return gw